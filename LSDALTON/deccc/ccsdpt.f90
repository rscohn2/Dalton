!> @file
!> DEC-CCSD(T) routines
!> \brief: ccsd(t) module
!> \author: Janus Juul Eriksen
!> \date: 2012-2013, Aarhus
module ccsdpt_module

#ifdef VAR_LSMPI
      use infpar_module
      use lsmpi_type
#endif
  use precision
  use dec_typedef_module
  use memory_handling
  use lstiming!, only: lstimer
  use screen_mod!, only: DECscreenITEM
  use BUILDAOBATCH
  use typedeftype!, only: Lsitem,lssetting
  use screen_mod!,only: free_decscreen, DECSCREENITEM
  use IntegralInterfaceDEC!, only: II_precalc_DECScreenMat,&
!       & II_getBatchOrbitalScreen, II_GET_DECPACKED4CENTER_J_ERI
  use IntegralInterfaceMOD



  ! DEC DEPENDENCIES (within deccc directory)  
  ! *****************************************
#ifdef VAR_LSMPI
      use decmpi_module
#endif
  use dec_fragment_utils
  use array2_simple_operations
  use array3_simple_operations
  use array4_simple_operations
  use dec_pdm_module
  use array_operations
  
  public :: ccsdpt_driver,ccsdpt_energy_e4_frag,ccsdpt_energy_e5_frag,&
       & ccsdpt_energy_e4_pair, ccsdpt_energy_e5_pair,&
       & ccsdpt_energy_e4_full, print_e4_full, ccsdpt_energy_e5_full,&
       & print_e5_full, ccsd_energy_full, print_ccsd_full
  private

contains

  !> \brief: driver routine for dec-ccsd(t)
  !> \author: Janus Juul Eriksen
  !> \date: july 2012
  subroutine ccsdpt_driver(nocc,nvirt,nbasis,ppfock,qqfock,ypo,ypv,mylsitem,ccsd_doubles,&
                         & ccsdpt_singles,ccsdpt_doubles)

    implicit none

    !> nocc, nvirt, and nbasis for fragment or full molecule
    integer, intent(in) :: nocc, nvirt, nbasis
    !> ppfock and qqfock for fragment or full molecule
    real(realk), intent(in) :: ppfock(nocc,nocc), qqfock(nvirt,nvirt)
    !> mo coefficents for occ and virt space for fragment or full molecule
    real(realk), intent(in) :: ypo(nbasis,nocc), ypv(nbasis,nvirt)
    !> mylsitem for fragment or full molecule
    type(lsitem), intent(inout) :: mylsitem
    !> ccsd doubles amplitudes
    type(array4), intent(inout) :: ccsd_doubles
    type(array) :: ccsd_doubles_portions ! o*v^2 portions of ccsd_doubles, 1 == i, 2 == j, 3 == k
    !> 2-el integrals
    type(array4) :: jaik ! integrals (AI|JK) in the order (J,A,I,K)
    type(array4) :: abij ! integrals (AI|BJ) in the order (A,B,I,J)
    ! cbai is of type DENSE, if this is a serial calculation, and TILED_DIST,
    ! if this is a parallel calculation
    type(array) :: cbai ! integrals (AI|BC) in the order (C,B,A,I)
#ifdef VAR_LSMPI
    type(array) :: cbai_pdm ! v^3 tiles from cbai, 1 == i, 2 == j, 3 == k
#endif
    !> integers
    integer :: i,j,k,idx,tuple_type
    !> mpi stuff
#ifdef VAR_LSMPI
    !> logical determining whether a parallel task should be joined by several procs
    logical :: collab
#endif
    !> orbital energies
    real(realk), pointer :: eivalocc(:), eivalvirt(:)
    !> MOs and unitary transformation matrices
    type(array2) :: C_can_occ, C_can_virt, Uocc, Uvirt
    !> dimensions
    integer, dimension(2) :: occdims, virtdims, virtoccdims
    integer, dimension(3) :: dims_aaa
    integer, dimension(4) :: dims_iaai, dims_aaii
    !> input for the actual triples computation
    type(array3) :: trip_tmp, trip_ampl
    type(array4) :: ccsdpt_doubles_2
    type(array4),intent(inout) :: ccsdpt_doubles
    type(array2),intent(inout) :: ccsdpt_singles

    ! init dimensions
    occdims = [nocc,nocc]
    virtdims = [nvirt,nvirt]
    virtoccdims = [nvirt,nocc]
    dims_iaai = [nocc,nvirt,nvirt,nocc]
    dims_aaii = [nvirt,nvirt,nocc,nocc]
    dims_aaa = [nvirt,nvirt,nvirt]

#ifdef VAR_LSMPI

    ! bcast the JOB specifier and distribute data to all the slaves within local group
    waking_the_slaves: if ((infpar%lg_nodtot .gt. 1) .and. (infpar%lg_mynum .eq. infpar%master)) then

       ! slaves are in lsmpi_slave routine (or corresponding dec_mpi_slave) and are now awaken
       call ls_mpibcast(CCSDPTSLAVE,infpar%master,infpar%lg_comm)

       ! distribute ccsd doubles and fragment or full molecule quantities to the slaves
       call mpi_communicate_ccsdpt_calcdata(nocc,nvirt,nbasis,ppfock,qqfock,ypo,ypv,ccsd_doubles%val,mylsitem)

    end if waking_the_slaves

#endif

    ! *************************************
    ! get arrays for transforming integrals
    ! *************************************
    ! C_can_occ, C_can_virt:  MO coefficients for canonical basis
    ! Uocc, Uvirt: unitary transformation matrices for canonical --> local basis (and vice versa)
    ! note: Uocc and Uvirt have indices (local,canonical)

    call mem_alloc(eivalocc,nocc)
    call mem_alloc(eivalvirt,nvirt)
    call get_ccsdpt_integral_transformation_matrices(nocc,nvirt,nbasis,ppfock,qqfock,ypo,ypv,&
                                       & C_can_occ,C_can_virt,Uocc,Uvirt,eivalocc,eivalvirt)

    ! ***************************************************
    ! get vo³, v²o², and v³o integrals in proper sequence
    ! ***************************************************
    ! note: the integrals are calculated in canonical basis

    call get_CCSDpT_integrals(mylsitem,nbasis,nocc,nvirt,C_can_occ%val,C_can_virt%val,jaik,abij,cbai)

    ! release occ and virt canonical MOs
    call array2_free(C_can_occ)
    call array2_free(C_can_virt)

    ! ***************************************************
    ! transform ccsd doubles amplitudes to diagonal basis
    ! ***************************************************

    call ccsdpt_local_can_trans(ccsd_doubles,nocc,nvirt,Uocc,Uvirt)

    ! Now we transpose the unitary transformation matrices as we will need these in the transformation
    ! of the ^{ccsd}T^{ab}_{ij}, ^{*}T^{a}_{i}, and ^{*}T^{ab}_{ij} amplitudes from canonical to local basis
    ! later on
    call array2_transpose(Uocc)
    call array2_transpose(Uvirt)

    ! ********************************
    ! begin actual triples calculation
    ! ********************************

    ! in all comments in the below, we employ the notation of eqs. (14.6.60) [with (i,j,k)/(a,c,d)]
    ! and (14.6.64).

    ! objective is three-fold:
    ! 1) calculate triples amplitudes, collect in array3 structures, trip_*** [canonical basis]
    ! 2) calculate ^{*}T^{a}_{i} and ^{*}T^{ab}_{ij} amplitudes in array2 and array4 structures, 
    !    ccsdpt_singles and ccsdpt_doubles [canonical basis]
    !    here: ccsdpt_doubles_2 is a temp array towards the generation of ccsdpt_doubles
    ! 3) transform ccsd_doubles, ccsdpt_singles and ccsdpt_doubles into local basis [local basis]

    ! *****************************************************
    ! ***************** trip generation *******************
    ! *****************************************************

    ! init ccsdpt_doubles_2 array4 structure.
    ! we merge ccsdpt_doubles and ccsdpt_doubles_2 at the end into ccsdpt_doubles. 
    ! we have dimensioned ccsdpt_doubles as dims_aaii and ccsdpt_doubles_2 as dims_iaai 
    ! in order to load in data consecutive in memory inside ccsdpt_contract_21 
    ! and ccsdpt_contract_22, respectively.
    ccsdpt_doubles_2 = array4_init_standard(dims_iaai)

    ! initially, reorder ccsd_doubles
    call array4_reorder(ccsd_doubles,[3,1,4,2]) ! ccsd_doubles(a,i,b,j) --> ccsd_doubles(b,a,j,i)

    ! init triples tuples array3 structures
    trip_tmp  = array3_init_standard(dims_aaa)
    trip_ampl = array3_init_standard(dims_aaa)

    ! init ccsd_doubles help array
    ccsd_doubles_portions = array_init([nocc,nvirt,nvirt,3],4)

    ! if cbai is tiled distributed, then put the three tiles into
    ! an array structure, cbai_pdm. here, initialize the array structure.

#ifdef VAR_LSMPI

    cbai_pdm = array_init([nvirt,nvirt,nvirt,3],4)

#endif

    ! a note on the mpi scheme.
    ! in order to minimize the number of mpi_get calls, we fork at the irun level.
    ! each node works on a separate i-tile ** as long as ** the remainder up to nocc is less than
    ! the total number of nodes within the local group. this way, no node will have to wait on the 
    ! remaining notes at the end of the i,j,k nested loop.
    !
    ! a note on the number of mpi_get calls.
    !  - at the irun level, there will be [(nocc - lg_nodtot + 1) + (lg_nodtot - 1) * lg_nodtot] number of calls,
    ! where (nocc - lg_nodtot + 1) is the number of 'collab == .false.' calls,
    ! and (lg_nodtot - 1) * lg_nodtot is the number of 'collab == .true.' calls
    !  - at the jrun level, there will be [(nocc/2) * (1 + nocc)] number of calls (minimum number of calls)
    !  - at the krun level, there will be [(nocc/6) * (nocc + 1) * (nocc + 2)] number of calls (minimum number of calls)

 irun: do i=1,nocc

#ifdef VAR_LSMPI

          if ((infpar%lg_nodtot + i - 1) .le. nocc) then

             collab = .false.
 
             ! determine if this is my job or not
             if (infpar%lg_mynum .ne. mod(i,infpar%lg_nodtot)) cycle irun
   
             ! get the i'th v^3 tile
             call array_get_tile(cbai,i,cbai_pdm%elm1(1:nvirt**3),nvirt**3)

          else

             collab = .true.
   
             ! get the i'th v^3 tile
             call array_get_tile(cbai,i,cbai_pdm%elm1(1:nvirt**3),nvirt**3)

          end if

#endif

          ! store portion of ccsd_doubles (the i'th index) to avoid unnecessary reorderings
          call array_reorder_3d(1.0E0_realk,ccsd_doubles%val(:,:,:,i),nvirt,nvirt,&
                  & nocc,[3,2,1],0.0E0_realk,ccsd_doubles_portions%elm4(:,:,:,1))

    jrun: do j=1,i

#ifdef VAR_LSMPI

             if (.not. collab) then

                ! get the j'th tile
                call array_get_tile(cbai,j,cbai_pdm%elm1(nvirt**3+1:2*nvirt**3),nvirt**3)

             else

                ! determine if this is my job or not
                if (infpar%lg_mynum .ne. mod(j,infpar%lg_nodtot)) cycle jrun
 
                ! get the j'th tile
                call array_get_tile(cbai,j,cbai_pdm%elm1(nvirt**3+1:2*nvirt**3),nvirt**3)

             end if

#endif

             ! store portion of ccsd_doubles (the j'th index) to avoid unnecessary reorderings
             call array_reorder_3d(1.0E0_realk,ccsd_doubles%val(:,:,:,j),nvirt,nvirt,&
                     & nocc,[3,2,1],0.0E0_realk,ccsd_doubles_portions%elm4(:,:,:,2))

       krun: do k=1,j

#ifdef VAR_LSMPI

                ! get the k'th tile
                call array_get_tile(cbai,k,cbai_pdm%elm1(2*nvirt**3+1:3*nvirt**3),nvirt**3)

#endif

                ! store portion of ccsd_doubles (the k'th index) to avoid unnecessary reorderings
                call array_reorder_3d(1.0E0_realk,ccsd_doubles%val(:,:,:,k),nvirt,nvirt,&
                        & nocc,[3,2,1],0.0E0_realk,ccsd_doubles_portions%elm4(:,:,:,3))

                ! select type of tuple
                tuple_type = -1
                ! i == j == k
                ! this always gives zero contribution
                ! i == j > k
                if ((i .eq. j) .and. (j .gt. k) .and. (i .gt. k)) tuple_type = 1
                ! i > j == k
                if ((i .gt. j) .and. (j .eq. k) .and. (i .gt. k)) tuple_type = 2
                ! i > j > k
                if ((i .gt. j) .and. (j .gt. k) .and. (i .gt. k)) tuple_type = 3

                ! generate tuple(s)
                TypeOfTuple: select case(tuple_type)

                case(1)

#ifdef VAR_LSMPI

                   ! generate the iik amplitude
                   call trip_amplitudes(i,i,k,nocc,nvirt,ccsd_doubles%val(:,:,i,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai_pdm%elm4(:,:,:,3),jaik%val(:,:,k,i),trip=trip_tmp)

                   trip_ampl%val = trip_tmp%val

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(k,i,i,nocc,nvirt,ccsd_doubles%val(:,:,i,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai_pdm%elm4(:,:,:,1),jaik%val(:,:,i,i),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(i,k,i,nocc,nvirt,ccsd_doubles%val(:,:,k,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai_pdm%elm4(:,:,:,1),jaik%val(:,:,i,k),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)

#else
   
                   ! generate the iik amplitude
                   call trip_amplitudes(i,i,k,nocc,nvirt,ccsd_doubles%val(:,:,i,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai%elm4(:,:,:,k),jaik%val(:,:,k,i),trip=trip_tmp)
  
                   trip_ampl%val = trip_tmp%val
  
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)
  
                   call trip_amplitudes(k,i,i,nocc,nvirt,ccsd_doubles%val(:,:,i,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai%elm4(:,:,:,i),jaik%val(:,:,i,i),trip=trip_tmp)
  
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)
  
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)
  
                   call trip_amplitudes(i,k,i,nocc,nvirt,ccsd_doubles%val(:,:,k,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai%elm4(:,:,:,i),jaik%val(:,:,i,k),trip=trip_tmp)
  
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)
  
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)

#endif
   
                   ! generate triples amplitudes from trip arrays

                   call trip_denom(i,i,k,nocc,nvirt,eivalocc,eivalvirt,trip_ampl%val)

                   ! now do the contractions

#ifdef VAR_LSMPI

                   call ccsdpt_driver_case1(i,k,nocc,nvirt,abij,jaik,&
                                        & cbai_pdm%elm4(:,:,:,1),cbai_pdm%elm4(:,:,:,3),&
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#else

                   call ccsdpt_driver_case1(i,k,nocc,nvirt,abij,jaik,&
                                        & cbai%elm4(:,:,:,i),cbai%elm4(:,:,:,k),&
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#endif

                case(2)

#ifdef VAR_LSMPI

                   ! generate the ijj amplitude
                   call trip_amplitudes(i,j,j,nocc,nvirt,ccsd_doubles%val(:,:,j,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai_pdm%elm4(:,:,:,2),jaik%val(:,:,j,j),trip=trip_tmp)
 
                   trip_ampl%val = trip_tmp%val
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(j,i,j,nocc,nvirt,ccsd_doubles%val(:,:,i,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai_pdm%elm4(:,:,:,2),jaik%val(:,:,j,i),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(j,j,i,nocc,nvirt,ccsd_doubles%val(:,:,j,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai_pdm%elm4(:,:,:,1),jaik%val(:,:,i,j),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)

#else

                   ! generate the ijj amplitude
                   call trip_amplitudes(i,j,j,nocc,nvirt,ccsd_doubles%val(:,:,j,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai%elm4(:,:,:,j),jaik%val(:,:,j,j),trip=trip_tmp)

                   trip_ampl%val = trip_tmp%val

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(j,i,j,nocc,nvirt,ccsd_doubles%val(:,:,i,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai%elm4(:,:,:,j),jaik%val(:,:,j,i),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(j,j,i,nocc,nvirt,ccsd_doubles%val(:,:,j,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai%elm4(:,:,:,i),jaik%val(:,:,i,j),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)

#endif

                   ! generate triples amplitudes from trip arrays

                   call trip_denom(i,j,j,nocc,nvirt,eivalocc,eivalvirt,trip_ampl%val)

                   ! now do the contractions

#ifdef VAR_LSMPI

                   call ccsdpt_driver_case2(i,j,nocc,nvirt,abij,jaik,&
                                        & cbai_pdm%elm4(:,:,:,1),cbai_pdm%elm4(:,:,:,2),&
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#else

                   call ccsdpt_driver_case2(i,j,nocc,nvirt,abij,jaik,&
                                        & cbai%elm4(:,:,:,i),cbai%elm4(:,:,:,j),&
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#endif

                case(3)

#ifdef VAR_LSMPI

                   ! generate the ijk amplitude
                   call trip_amplitudes(i,j,k,nocc,nvirt,ccsd_doubles%val(:,:,j,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai_pdm%elm4(:,:,:,3),jaik%val(:,:,k,j),trip=trip_tmp)
 
                   trip_ampl%val = trip_tmp%val
 
                   call trip_amplitudes(k,i,j,nocc,nvirt,ccsd_doubles%val(:,:,i,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai_pdm%elm4(:,:,:,2),jaik%val(:,:,j,i),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(j,k,i,nocc,nvirt,ccsd_doubles%val(:,:,k,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai_pdm%elm4(:,:,:,1),jaik%val(:,:,i,k),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(i,k,j,nocc,nvirt,ccsd_doubles%val(:,:,k,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai_pdm%elm4(:,:,:,2),jaik%val(:,:,j,k),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(j,i,k,nocc,nvirt,ccsd_doubles%val(:,:,i,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai_pdm%elm4(:,:,:,3),jaik%val(:,:,k,i),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)
 
                   call trip_amplitudes(k,j,i,nocc,nvirt,ccsd_doubles%val(:,:,j,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai_pdm%elm4(:,:,:,1),jaik%val(:,:,i,j),trip=trip_tmp)
 
                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)

#else

                   ! generate the ijk amplitude
                   call trip_amplitudes(i,j,k,nocc,nvirt,ccsd_doubles%val(:,:,j,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai%elm4(:,:,:,k),jaik%val(:,:,k,j),trip=trip_tmp)

                   trip_ampl%val = trip_tmp%val

                   call trip_amplitudes(k,i,j,nocc,nvirt,ccsd_doubles%val(:,:,i,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai%elm4(:,:,:,j),jaik%val(:,:,j,i),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,3,1],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(j,k,i,nocc,nvirt,ccsd_doubles%val(:,:,k,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai%elm4(:,:,:,i),jaik%val(:,:,i,k),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,1,2],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(i,k,j,nocc,nvirt,ccsd_doubles%val(:,:,k,i),ccsd_doubles_portions%elm4(:,:,:,1),&
                           & cbai%elm4(:,:,:,j),jaik%val(:,:,j,k),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[1,3,2],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(j,i,k,nocc,nvirt,ccsd_doubles%val(:,:,i,j),ccsd_doubles_portions%elm4(:,:,:,2),&
                           & cbai%elm4(:,:,:,k),jaik%val(:,:,k,i),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[2,1,3],1.0E0_realk,trip_ampl%val)

                   call trip_amplitudes(k,j,i,nocc,nvirt,ccsd_doubles%val(:,:,j,k),ccsd_doubles_portions%elm4(:,:,:,3),&
                           & cbai%elm4(:,:,:,i),jaik%val(:,:,i,j),trip=trip_tmp)

                   call array_reorder_3d(1.0E0_realk,trip_tmp%val,nvirt,nvirt,&
                           & nvirt,[3,2,1],1.0E0_realk,trip_ampl%val)

#endif

                   ! generate triples amplitudes from trip arrays

                   call trip_denom(i,j,k,nocc,nvirt,eivalocc,eivalvirt,trip_ampl%val)

                   ! now do the contractions

#ifdef VAR_LSMPI

                   call ccsdpt_driver_case3(i,j,k,nocc,nvirt,abij,jaik,&
                                        & cbai_pdm%elm4(:,:,:,1),cbai_pdm%elm4(:,:,:,2),cbai_pdm%elm4(:,:,:,3),&
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#else

                   call ccsdpt_driver_case3(i,j,k,nocc,nvirt,abij,jaik,&
                                        & cbai%elm4(:,:,:,i),cbai%elm4(:,:,:,j),cbai%elm4(:,:,:,k),& 
                                        & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip_ampl)

#endif

                end select TypeOfTuple

             end do krun
          end do jrun
       end do irun

    ! *************************************************
    ! *********** done w/ trip generation *************
    ! *************************************************

    ! now release trip_ijk, trip_kji, trip_jki, trip_ikj, trip_jik, and trip_kji array3s
    call array3_free(trip_tmp)
    call array3_free(trip_ampl)

    ! also, release ccsd_doubles help array
    call array_free(ccsd_doubles_portions)

#ifdef VAR_LSMPI

    ! reduce singles and doubles arrays into that residing on the master
    reducing_to_master: if (infpar%lg_nodtot .gt. 1) then

       call lsmpi_local_reduction(ccsdpt_singles%val,nocc,nvirt,infpar%master)
       call lsmpi_local_reduction(ccsdpt_doubles%val,nvirt,nocc,nvirt,nocc,infpar%master)
       call lsmpi_local_reduction(ccsdpt_doubles_2%val,nvirt,nocc,nvirt,nocc,infpar%master)

    end if reducing_to_master

    ! release stuff located on slaves
    releasing_the_slaves: if ((infpar%lg_nodtot .gt. 1) .and. (infpar%lg_mynum .ne. infpar%master)) then

       ! release stuff initialized herein
       call array2_free(Uocc)
       call array2_free(Uvirt)
       call array4_free(ccsdpt_doubles_2) 
       call mem_dealloc(eivalocc)
       call mem_dealloc(eivalvirt)
       call array4_free(abij)
       call array_free(cbai)
       call array_free(cbai_pdm)
       call array4_free(jaik)

       ! now, release the slaves  
       return

    end if releasing_the_slaves

#endif

    ! now everything resides on the master...

    ! collect ccsdpt_doubles and ccsdpt_doubles_2 into ccsdpt_doubles array4 structure
    ! ccsdpt_doubles(a,b,i,j) = ccsdpt_doubles(a,b,i,j) + ccsdpt_doubles_2(j,a,b,i) (*)
    ! (*) here, ccsdpt_doubles_2 is simultaneously reordered as (j,a,b,i) --> (a,b,i,j)
    call array_reorder_4d(1.0E0_realk,ccsdpt_doubles_2%val,ccsdpt_doubles_2%dims(1),&
                               &ccsdpt_doubles_2%dims(2),ccsdpt_doubles_2%dims(3),ccsdpt_doubles_2%dims(4),&
                               &[2,3,4,1],1.0E0_realk,ccsdpt_doubles%val)

    ! release ccsdpt_doubles_2 array4 structure
    call array4_free(ccsdpt_doubles_2)

    ! *************************************************
    ! ***** do canonical --> local transformation *****
    ! *************************************************

    call ccsdpt_can_local_trans(ccsd_doubles,ccsdpt_singles,ccsdpt_doubles,nocc,nvirt,Uocc,Uvirt)

    ! now, release Uocc and Uvirt
    call array2_free(Uocc)
    call array2_free(Uvirt)

    ! clean up
    call mem_dealloc(eivalocc)
    call mem_dealloc(eivalvirt)
    call array4_free(abij)
    call array_free(cbai)
#ifdef VAR_LSMPI
    call array_free(cbai_pdm)
#endif
    call array4_free(jaik)

    ! **************************************************************
    ! *** do final reordering of amplitudes and clean the dishes ***
    ! **************************************************************

    ! reorder ccsdpt_doubles and ccsd_doubles back to (a,b,i,j) sequence
    call array4_reorder(ccsdpt_doubles,[3,4,1,2])
    call array4_reorder(ccsd_doubles,[4,3,2,1])

  end subroutine ccsdpt_driver


  !> \brief: driver routine for contractions in case(1) of ccsdpt_driver
  !> \author: Janus Juul Eriksen
  !> \date: march 2013
  subroutine ccsdpt_driver_case1(oindex1,oindex3,no,nv,abij,jaik,&
                            & int_virt_tile_o1,int_virt_tile_o3,&
                            & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip)

    implicit none

    !> i, j, k, nocc, and nvirt
    integer, intent(in) :: oindex1,oindex3,no,nv
    !> ccsd(t) singles and doubles amplitudes
    type(array2), intent(inout) :: ccsdpt_singles
    type(array4), intent(inout) :: ccsdpt_doubles
    type(array4), intent(inout) :: ccsdpt_doubles_2
    !> aibj and jaik 2-el integrals
    type(array4), intent(inout) :: jaik ! integrals (AI|JK) in the order (J,A,I,K)
    type(array4), intent(inout) :: abij ! integrals (AI|BJ) in the order (A,B,I,J)
    !> tiles of cbai 2-el integrals determined by incomming oindex1,oindex3
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o1
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o3
    !> triples amplitude
    type(array3), intent(inout) :: trip
    !> loop integer
    integer :: idx

    ! before the calls to the contractions in ccsdpt_contract_211/212 and ccsdpt_contract_221/222,
    ! we do a [2,3,1] reordering. in order to minimize the number of reorderings needed to be
    ! performed, and in order to take optimal advantage of the symmetry of the amplitudes, we carry out
    ! the amplitudes in accordance to the following scheme
    !
    ! iik(a,b,c) --> iik(b,c,a) --> iik(c,a,b) == this is the kii amplitude
    ! similarly, we get:
    ! kii --> kii --> kii == iki
    ! iki --> iki --> iki, and then we are DONE for our choice of 'ijk'

    do idx = 1,3

       ! calculate contribution to ccsdpt_singles:

       if (idx .eq. 1) then

          call ccsdpt_contract_11(oindex1,oindex1,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex1,oindex1,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex1,oindex1,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3,.false.)
          call ccsdpt_contract_212(oindex1,oindex1,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex1,oindex1,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex1,oindex1,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 2) then

          call ccsdpt_contract_11(oindex3,oindex1,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.true.)
          call ccsdpt_contract_12(oindex3,oindex1,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.true.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex3,oindex1,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1,.false.)
          call ccsdpt_contract_212(oindex3,oindex1,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex3,oindex1,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex3,oindex1,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 3) then

          ! iki: this case is redundant since both the coulumb and the exchange contributions
          ! will be contructed from the ampl_iki trip amplitudes and therefore end up
          ! canceling each other when added to ccsdpt_singles

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex1,oindex3,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1,.true.)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex1,oindex3,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.true.)

       end if

    end do

  end subroutine ccsdpt_driver_case1


  !> \brief: driver routine for contractions in case(2) of ccsdpt_driver
  !> \author: Janus Juul Eriksen
  !> \date: march 2013
  subroutine ccsdpt_driver_case2(oindex1,oindex2,no,nv,abij,jaik,&
                            & int_virt_tile_o1,int_virt_tile_o2,&
                            & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip)

    implicit none

    !> i, j, k, nocc, and nvirt
    integer, intent(in) :: oindex1,oindex2,no,nv
    !> ccsd(t) singles and doubles amplitudes
    type(array2), intent(inout) :: ccsdpt_singles
    type(array4), intent(inout) :: ccsdpt_doubles
    type(array4), intent(inout) :: ccsdpt_doubles_2
    !> aibj and jaik 2-el integrals
    type(array4), intent(inout) :: jaik ! integrals (AI|JK) in the order (J,A,I,K)
    type(array4), intent(inout) :: abij ! integrals (AI|BJ) in the order (A,B,I,J)
    !> tiles of cbai 2-el integrals determined by incomming oindex1,oindex2
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o1
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o2
    !> triples amplitude
    type(array3), intent(inout) :: trip
    !> loop integer
    integer :: idx

    ! before the calls to the contractions in ccsdpt_contract_211/212 and ccsdpt_contract_221/222,
    ! we do a [2,3,1] reordering. in order to minimize the number of reorderings needed to be
    ! performed, and in order to take optimal advantage of the symmetry of the amplitudes, we carry out
    ! the amplitudes in accordance to the following scheme
    !
    ! ijj(a,b,c) --> ijj(b,c,a) --> ijj(c,a,b) == this is the jij amplitude
    ! similarly, we get:
    ! jij --> jij --> jij == jji
    ! jji --> jji --> jji, and then we are DONE for our choice of 'ijk'

    do idx = 1,3

       ! calculate contributions to ccsdpt_singles:

       if (idx .eq. 1) then
   
          call ccsdpt_contract_11(oindex1,oindex2,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.true.)
          call ccsdpt_contract_12(oindex1,oindex2,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.true.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex1,oindex2,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2,.false.)
          call ccsdpt_contract_212(oindex1,oindex2,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex1,oindex2,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex1,oindex2,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 2) then
   
          ! this case is redundant since both the coulumb and the exchange contributions
          ! will be contructed from the ampl_jij trip amplitudes and therefore end up
          ! canceling each other when added to T_star
   
          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex2,oindex1,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2,.true.)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex2,oindex1,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.true.)

       else if (idx .eq. 3) then
   
          call ccsdpt_contract_11(oindex2,oindex2,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex2,oindex2,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
   
          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex2,oindex2,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1,.false.)
          call ccsdpt_contract_212(oindex2,oindex2,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex2,oindex2,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex2,oindex2,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       end if

    end do

  end subroutine ccsdpt_driver_case2


  !> \brief: driver routine for contractions in case(3) of ccsdpt_driver
  !> \author: Janus Juul Eriksen
  !> \date: march 2013
  subroutine ccsdpt_driver_case3(oindex1,oindex2,oindex3,no,nv,abij,jaik,&
                            & int_virt_tile_o1,int_virt_tile_o2,int_virt_tile_o3,&
                            & ccsdpt_singles,ccsdpt_doubles,ccsdpt_doubles_2,trip)

    implicit none

    !> i, j, k, nocc, and nvirt
    integer, intent(in) :: oindex1,oindex2,oindex3,no,nv
    !> ccsd(t) singles and doubles amplitudes
    type(array2), intent(inout) :: ccsdpt_singles
    type(array4), intent(inout) :: ccsdpt_doubles
    type(array4), intent(inout) :: ccsdpt_doubles_2
    !> aibj and jaik 2-el integrals
    type(array4), intent(inout) :: jaik ! integrals (AI|JK) in the order (J,A,I,K)
    type(array4), intent(inout) :: abij ! integrals (AI|BJ) in the order (A,B,I,J)
    !> tiles of cbai 2-el integrals determined by incomming oindex1,oindex2,oindex3
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o1
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o2
    real(realk), dimension(nv,nv,nv), intent(inout) :: int_virt_tile_o3
    !> triples amplitude
    type(array3), intent(inout) :: trip
    !> loop integer
    integer :: idx

    ! before the calls to the contractions in ccsdpt_contract_211/212 and ccsdpt_contract_221/222,
    ! we do a [2,3,1] reordering. in order to minimize the number of reorderings needed to be
    ! performed, and in order to take optimal advantage of the symmetry of the amplitudes, we carry out
    ! the amplitudes in accordance to the following scheme
    !
    ! ijk(a,b,c) --> ijk(b,c,a) --> ijk(c,a,b) == this is the kij amplitude
    ! similarly, we get:
    ! kij --> kij --> kij == jki
    ! jki --> jki --> jki == ijk, thus at idx .eq. 3, we need to do a [3,2,1] reordering to get
    ! the kji amplitude. then we continue as above
    ! kji --> kji --> kji == ikj
    ! ikj --> ikj --> ikj == jik
    ! jik --> jik --> jik, and then we are DONE for our choice of 'ijk'

    do idx = 1,6

       ! calculate contributions to ccsdpt_singles:

       if (idx .eq. 1) then

          call ccsdpt_contract_11(oindex1,oindex2,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex1,oindex2,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex1,oindex2,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3,.false.)
          call ccsdpt_contract_212(oindex1,oindex2,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex1,oindex2,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex1,oindex2,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 2) then

          call ccsdpt_contract_11(oindex3,oindex1,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex3,oindex1,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex3,oindex1,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2,.false.)
          call ccsdpt_contract_212(oindex3,oindex1,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex3,oindex1,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex3,oindex1,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 3) then

          call ccsdpt_contract_11(oindex2,oindex3,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex2,oindex3,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex2,oindex3,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1,.false.)
          call ccsdpt_contract_212(oindex2,oindex3,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex2,oindex3,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex2,oindex3,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 4) then

          !******
          !
          ! generate the kji amplitude (see note above)
          call array3_reorder(trip,[3,2,1])
          !
          !******

          call ccsdpt_contract_11(oindex3,oindex2,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex3,oindex2,oindex1,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex3,oindex2,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1,.false.)
          call ccsdpt_contract_212(oindex3,oindex2,oindex1,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex3,oindex2,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex3,oindex2,oindex1,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 5) then

          call ccsdpt_contract_11(oindex1,oindex3,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex1,oindex3,oindex2,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex1,oindex3,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2,.false.)
          call ccsdpt_contract_212(oindex1,oindex3,oindex2,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o1)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex1,oindex3,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex1,oindex3,oindex2,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       else if (idx .eq. 6) then

          call ccsdpt_contract_11(oindex2,oindex1,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)
          call ccsdpt_contract_12(oindex2,oindex1,oindex3,nv,abij,ccsdpt_singles,&
                       & trip,.false.)

          ! calculate contributions to ccsdpt_doubles (virt part):

          ! initially, reorder trip
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_211(oindex2,oindex1,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o3,.false.)
          call ccsdpt_contract_212(oindex2,oindex1,oindex3,nv,&
                           & ccsdpt_doubles,trip,int_virt_tile_o2)

          ! now do occ part:

          ! reorder trip yet again
          call array3_reorder(trip,[2,3,1])

          call ccsdpt_contract_221(oindex2,oindex1,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip,.false.)
          call ccsdpt_contract_222(oindex2,oindex1,oindex3,no,nv,jaik,&
                           & ccsdpt_doubles_2,trip)

       end if

    end do

  end subroutine ccsdpt_driver_case3


  !> \brief: transform ccsd doubles from local to canonical basis
  !> \author: Janus Juul Eriksen
  !> \date: september 2012
  !> \param: ccsd_t2, no and nv are nocc and nvirt, respectively, and U_occ and U_virt
  !          are unitary matrices from local --> canonical basis
  subroutine ccsdpt_local_can_trans(ccsd_t2,no,nv,U_occ,U_virt)

    implicit none
    !> ccsd doubles
    type(array4), intent(inout) :: ccsd_t2
    !> unitary transformation matrices
    type(array2), intent(inout) :: U_occ, U_virt
    !> integers
    integer, intent(in) :: no, nv
    !> temp array4 structures
    type(array4) :: tmp1, tmp2

    ! (a,i,b,j) are local basis indices and (A,I,B,J) refer to the canonical basis.
    ! we want to carry out the transformation:
    ! T^{AB}_{IJ} = sum_{aibj} U_{aA} U_{iI} U_{bB} U_{jJ} T^{ab}_{ij}

    ! 1. Init temporary arrays, dims = aiai
    tmp1 = array4_init_standard([nv,no,nv,no])

    ! 2. 1st index: doub_ampl(a,i,b,j) --> tmp1(A,i,b,j)
    call array4_contract1(ccsd_t2,U_virt,tmp1,.true.)
    call array4_free(ccsd_t2)

    ! 3. 2nd index: tmp1(A,i,b,j) --> tmp1(i,A,b,j) --> tmp2(I,A,b,j)
    call array4_reorder(tmp1,[2,1,3,4])
    tmp2 = array4_init_standard([no,nv,nv,no])
    call array4_contract1(tmp1,U_occ,tmp2,.true.)
    call array4_free(tmp1)

    ! 4. 3rd index: tmp2(I,A,b,j) --> tmp2(j,b,A,I) --> tmp1(J,b,A,I)
    call array4_reorder(tmp2,[4,3,2,1])
    tmp1 = array4_init_standard([no,nv,nv,no])
    call array4_contract1(tmp2,U_occ,tmp1,.true.)
    call array4_free(tmp2)

    ! 5. 4th index: tmp1(J,b,A,I) --> tmp1(b,J,A,I) --> doub_ampl(B,J,A,I) = doub_ampl(A,I,B,J)
    call array4_reorder(tmp1,[2,1,3,4])
    ccsd_t2 = array4_init_standard([nv,no,nv,no])
    call array4_contract1(tmp1,U_virt,ccsd_t2,.true.)
    call array4_free(tmp1)

  end subroutine ccsdpt_local_can_trans


  !> \brief: transform ccsd_doubles, ccsdpt_singles and ccsdpt_doubles from canonical to local basis
  !> \author: Janus Juul Eriksen
  !> \date: september 2012
  !> \param: ccsd_t2, ccsdpt_t1, ccsdpt_t2, no and nv are nocc and nvirt, respectively, 
  !<         and U_occ and U_virt are unitary matrices from canonical --> local basis
  subroutine ccsdpt_can_local_trans(ccsd_t2,ccsdpt_t1,ccsdpt_t2,no,nv,U_occ,U_virt)

    implicit none
    !> ccsdpt_singles
    type(array2), intent(inout) :: ccsdpt_t1
    !> ccsd_doubles and ccsdpt_doubles
    type(array4), intent(inout) :: ccsd_t2, ccsdpt_t2
    !> unitary transformation matrices
    type(array2), intent(inout) :: U_occ, U_virt
    !> integers
    integer, intent(in) :: no, nv
    !> temp array2 and array4 structures
    type(array2) :: tmp0
    type(array4) :: tmp1, tmp2, tmp3, tmp4

    ! (a,i,b,j) are local basis indices and (A,I,B,J) refer to the canonical basis.

    ! 1a. init temporary array4s, tmp1 and tmp3
    tmp1 = array4_init_standard([nv,nv,no,no])
    tmp3 = array4_init_standard([nv,nv,no,no])
    ! 1b. init temporary array2, tmp0
    tmp0 = array2_init_plain([nv,no])

    ! 2. 1st index:
    ! ccsdpt_t2(A,B,I,J) --> tmp1(a,B,I,J)
    ! ccsd_t2(B,A,J,I) --> tmp3(b,A,J,I)
    call array4_contract1(ccsdpt_t2,U_virt,tmp1,.true.)
    call array4_contract1(ccsd_t2,U_virt,tmp3,.true.)
    ! ccsdpt_t1(A,I) --> tmp0(a,I)
    call array2_matmul(U_virt,ccsdpt_t1,tmp0,'t','n',1.0E0_realk,0.0E0_realk)

    ! free ccsdpt_doubles and ccsd_doubles
    call array4_free(ccsdpt_t2)
    call array4_free(ccsd_t2)

    ! 3. 2nd index:
    ! tmp1(a,B,I,J) --> tmp1(B,a,I,J) --> tmp2(b,a,I,J)
    ! tmp3(b,A,J,I) --> tmp3(A,b,J,I) --> tmp4(a,b,J,I) 
    ! tmp0(a,I) --> ccsdpt_t1(a,i)
    call array4_reorder(tmp1,[2,1,3,4])
    call array4_reorder(tmp3,[2,1,3,4])

    ! init temporary array4s, tmp2 and tmp4
    tmp2 = array4_init_standard([nv,nv,no,no])
    tmp4 = array4_init_standard([nv,nv,no,no])

    ! transformation time - ccsdpt_doubles and ccsd_doubles case
    call array4_contract1(tmp1,U_virt,tmp2,.true.)
    call array4_contract1(tmp3,U_virt,tmp4,.true.)
    ! ccsdpt_singles case
    call array2_matmul(tmp0,U_occ,ccsdpt_t1,'n','n',1.0E0_realk,0.0E0_realk)

    ! free tmp1 and tmp3
    call array4_free(tmp1)
    call array4_free(tmp3)
    ! free tmp0
    call array2_free(tmp0)

    ! 4. 3rd index:
    ! tmp2(b,a,I,J) --> tmp2(J,I,a,b) --> tmp1(j,I,a,b)
    ! tmp4(a,b,J,I) --> tmp4(I,J,b,a) --> tmp3(i,J,b,a)
    call array4_reorder(tmp2,[4,3,2,1])
    call array4_reorder(tmp4,[4,3,2,1])

    ! init temporary array4s, tmp1 and tmp3, once again
    tmp1 = array4_init_standard([no,no,nv,nv])
    tmp3 = array4_init_standard([no,no,nv,nv])

    ! transformation time
    call array4_contract1(tmp2,U_occ,tmp1,.true.)
    call array4_contract1(tmp4,U_occ,tmp3,.true.)

    ! free tmp2 and tmp4
    call array4_free(tmp2)
    call array4_free(tmp4)

    ! 5. 4th index:
    ! tmp1(j,I,a,b) --> tmp1(I,j,a,b) --> ccsdpt_doubles(i,j,a,b)
    ! tmp3(i,J,b,a) --> tmp3(J,i,b,a) --> ccsd_doubles(j,i,b,a)
    call array4_reorder(tmp1,[2,1,3,4])
    call array4_reorder(tmp3,[2,1,3,4])

    ! init ccsdpt_t2 and ccsd_t2 array4s once again
    ccsdpt_t2 = array4_init_standard([no,no,nv,nv])
    ccsd_t2 = array4_init_standard([no,no,nv,nv])

    ! transformation time
    call array4_contract1(tmp1,U_occ,ccsdpt_t2,.true.)
    call array4_contract1(tmp3,U_occ,ccsd_t2,.true.)

    ! free tmp1 and tmp3
    call array4_free(tmp1)
    call array4_free(tmp3)

  end subroutine ccsdpt_can_local_trans


  !> \brief: create a triples amplitude ([a,b,c] tuple) for a fixed [i,j,k] tuple, that is, t^{***}_{ijk}
  !          saved as an array3 structure (amplitudes)
  !> \author: Janus Juul Eriksen
  !> \date: july 2012
  !> \param: oindex1, oindex2, and oindex3 are the three occupied indices of the outer loop in the ccsd(t) driver
  !> \param: no and nv are nocc and nvirt, respectively
  !> \param: doub_ampl are ccsd ampltidues, t^{ab}_{ij}
  !> \param: int_virt and int_occ are v^3 part of cbai and jaik of driver routine, respectively
  !> \param: trp_ampl is the final triples amplitude tuple [a,b,c], that is, of the size (virt)³ kept in memory
  subroutine trip_amplitudes(oindex1,oindex2,oindex3,no,nv,doub_ampl_v2,doub_ampl_ov2,int_virt_tile,&
                     & int_occ_portion,trip)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, no, nv
    real(realk), dimension(nv,nv,nv), intent(in) :: int_virt_tile
    real(realk), dimension(no,nv), intent(in) :: int_occ_portion
    real(realk), dimension(no,nv,nv), intent(in) :: doub_ampl_ov2
    real(realk), dimension(nv,nv), intent(in) :: doub_ampl_v2
    type(array3), intent(inout) :: trip
    !> temporary quantities
    integer :: idx!,collection_type
    type(array3) :: trip_interm!,interm_1, interm_2

    ! important: notation adapted from eq. (14.6.60) of MEST. herein, 'e' and 'm' are the running indices of the
    ! equation in the book (therein: 'd' and 'l', respectively)

    ! NOTE: incoming array structures are ordered according to:
    ! canTaibj(a,b,j,i) - in doub_ampl_v2 we have (a,b), in doub_ampl_ov2 we have (j,a,b) 
    ! int_virt_tile(c,b,a,i) - only (c,a,b)
    ! canAIJK(j,a,i,k) - only (j,a)

    ! ***************************************************
    ! ** contraction time (over the virtual index 'e') **
    ! ***************************************************

    ! first, zero the temp array
    trip%val = 0.0E0_realk

    ! do v^4o^3 contraction
!    do idx = 1,nv
!
!       call dgemm('t','n',nv,nv,nv,1.0E0_realk,doub_ampl_v2,nv,int_virt_tile(:,:,idx),nv,&
!                      & 1.0E0_realk,trip%val(:,:,idx),nv)
!
!    end do
    ! alternative rectangular version
    call dgemm('t','n',nv,nv**2,nv,1.0E0_realk,doub_ampl_v2,nv,int_virt_tile,nv,&
                   & 1.0E0_realk,trip%val,nv)

    ! ****************************************************
    ! ** contraction time (over the occupied index 'm') **
    ! ****************************************************

    ! init temp array
    trip_interm = array3_init_standard([nv,nv,nv])

    ! do v^3o^4 contraction
!    do idx = 1,nv
!
!       call dgemm('t','n',nv,nv,no,1.0E0_realk,int_occ_portion,no,doub_ampl_ov2(:,:,idx),no,&
!                      & 1.0E0_realk,trip_interm%val(:,:,idx),nv)
!
!    end do
    ! alternative rectangular version
    call dgemm('t','n',nv,nv**2,no,1.0E0_realk,int_occ_portion,no,doub_ampl_ov2,no,&
                   & 1.0E0_realk,trip_interm%val,nv)

    ! ********************************************************************
    ! *** collect the two contributions into a common array3 structure ***
    ! ********************************************************************

    ! interm_1(a,b,c) = interm_1(a,b,c) - interm_2(a,b,c) (*)
    ! (*) here, trip_interm is simultaneously reordered as (c,a,b) --> (a,b,c)
    call array_reorder_3d(-1.0E0_realk,trip_interm%val,trip_interm%dims(1),trip_interm%dims(2),&
                           & trip_interm%dims(3),[2,3,1],1.0E0_realk,trip%val)

    ! release trip_interm array3 structure
    call array3_free(trip_interm)

  end subroutine trip_amplitudes


  !> \brief: multiply the [a,b,c] triples ampl. by the orbital energy difference.
  !> \author: Janus Juul Eriksen
  !> \date: july 2012
  !> \param: oindex1, oindex2, and oindex3 are the three occupied indices of the outer loop in the ccsd(t) driver
  !> \param: no and nv are nocc and nvirt, respectively
  !> \param: eigenocc and eigenvirt are vectors containing occupied and virtual orbital energies, respectively
  !> \param: amplitudes are the final triples amplitude tuple [a,b,c], that is, of the size (virt)³ kept in memory
  subroutine trip_denom(oindex1,oindex2,oindex3,no,nv,eigenocc,eigenvirt,trip)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, no, nv
    real(realk) :: eigenocc(no), eigenvirt(nv)
    real(realk), dimension(nv,nv,nv), intent(inout) :: trip
    !> temporary quantities
    integer :: trip_type, a, b, c
    real(realk) :: e_orb, e_orb_occ

    ! at first, calculate the sum of the three participating occupied orbital energies, as this
    ! is a constant for the three incomming occupied indices

    e_orb_occ = eigenocc(oindex1) + eigenocc(oindex2) + eigenocc(oindex3)

         !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(a,b,c,e_orb),SHARED(nv,trip,eigenvirt,e_orb_occ)
 arun_0: do a=1,nv
    brun_0: do b=1,nv
       crun_0: do c=1,nv

                  e_orb = -1.0E0_realk / (eigenvirt(a) + eigenvirt(b) + eigenvirt(c) - e_orb_occ)

                  trip(c,b,a) = trip(c,b,a) * e_orb

               end do crun_0
            end do brun_0
         end do arun_0
         !$OMP END PARALLEL DO

  end subroutine trip_denom


  !> brief: do the first of the two contraction over 'cdkl' (here: 'c' and 'd', 'k' and 'l' are summations in driver routine)
  !         in eq. (14.6.63) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine. int_normal is abij of driver.
  !> nv is nvirt and T_star is ccsdpt_singles of driver. trip_ampl is the triples amplitude array.
  subroutine ccsdpt_contract_11(oindex1,oindex2,oindex3,nv,int_normal,T_star,trip_ampl,special)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, nv
    type(array2), intent(inout) :: T_star
    type(array4), intent(inout) :: int_normal
    type(array3), optional, intent(inout) :: trip_ampl
    logical, intent(in) :: special
    !> temporary quantities
    integer :: contraction_type
    real(realk), pointer :: interm_cou(:), interm_exc(:)

    ! NOTE: incoming array4 structures are ordered according to:
    ! canAIBJ(c,d,k,l) (MEST nomenclature)
    ! T_ast_0(a,i)

    ! determine which type of contraction is to be performed
    contraction_type = -1
    ! is this a special contraction, i.e., can we handle 211 and 212 contractions in one go?
    if (special) contraction_type = 0
    ! otherwise, do the default 211 contraction
    if (.not. special) contraction_type = 1

    ! contraction time (here: over virtual indices 'c' and 'd') with "coulumb minus exchange"
    ! version of canAIBJ (2 * canAIJK(c,k,d,l) - canAIBC(c,l,d,k))

    ! init temporary pointers
    call mem_alloc(interm_cou,nv)
    call mem_alloc(interm_exc,nv)

    TypeofContraction_11: select case(contraction_type)

    case(0)

       ! canAIBJ(c,d,k,l) --> tmp_g_1(c,d) (coulumb)
       ! here, the coulumb and exchange parts will be equal and we thus only need to contract with the coulumb part. 

       ! now contract coulumb term over both indices into interm_cou(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex2,oindex3),&
                & nv**2,0.0E0_realk,interm_cou,nv)

       ! as the exchange contributions for the present case will be the same as the
       ! coulumb contributions, we do not need to construct these as we may include them
       ! implicitly by only adding 1*coulumb

       ! now collect in T_star array2 structure
       call daxpy(nv,1.0E0_realk,interm_cou,1,T_star%val(:,oindex1),1)

    case(1)

       ! canAIBJ(c,d,k,l) --> tmp_g_1(c,d) (coulumb)
       ! canAIBJ(c,d,l,k) --> tmp_g_2(c,d) (exchange)

       ! now contract coulumb term over both indices into interm_cou(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex2,oindex3),&
                & nv**2,0.0E0_realk,interm_cou,nv)

       ! now contract exchange term over both indices into interm_exc(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex3,oindex2),&
                & nv**2,0.0E0_realk,interm_exc,nv)

       ! now collect in T_star array2 structure
       call daxpy(nv,2.0E0_realk,interm_cou,1,T_star%val(:,oindex1),1)
       call daxpy(nv,-1.0E0_realk,interm_exc,1,T_star%val(:,oindex1),1)

    end select TypeofContraction_11

    ! release temporary stuff
    call mem_dealloc(interm_cou)
    call mem_dealloc(interm_exc)

  end subroutine ccsdpt_contract_11

  !> brief: do the second of the two contraction over 'cdkl' (here: 'c' and 'd', 'k' and 'l' are summations in driver routine)
  !         in eq. (14.6.63) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine. int_normal is abij of driver.
  !> nv is nvirt and T_star is ccsdpt_singles of driver. trip_ampl is the triples amplitude array.
  subroutine ccsdpt_contract_12(oindex1,oindex2,oindex3,nv,int_normal,T_star,trip_ampl,special)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, nv
    type(array2), intent(inout) :: T_star
    type(array4), intent(inout) :: int_normal
    type(array3), optional, intent(inout) :: trip_ampl
    logical, intent(in) :: special
    !> temporary quantities
    integer :: contraction_type!, idx, p0(5), p1(6), p2(6), p3(6)
    real(realk), pointer :: interm_cou(:), interm_exc(:)!, interm_cou_2(:), interm_exc_2(:)

    ! NOTE: incoming array4 structures are ordered according to:
    ! canAIBJ(c,d,k,l) (MEST nomenclature)
    ! T_ast_0(a,i)

    ! contraction time (here: over virtual indices 'c' and 'd') with "coulumb minus exchange"
    ! version of canAIBJ (2 * canAIJK(c,k,d,l) - canAIBC(c,l,d,k))

    ! determine which type of contraction is to be performed
    contraction_type = -1
    ! is this a special contraction, i.e., can we handle 211 and 212 contractions in one go?
    if (special) contraction_type = 0
    ! otherwise, do the default 211 contraction
    if (.not. special) contraction_type = 1

    ! contraction time (here: over virtual indices 'c' and 'd') with "coulumb minus exchange"
    ! version of canAIBJ (2 * canAIJK(c,k,d,l) - canAIBC(c,l,d,k))

    ! init temporary pointers
    call mem_alloc(interm_cou,nv)
    call mem_alloc(interm_exc,nv)

    TypeofContraction_12: select case(contraction_type)

    case(0)

       ! canAIBJ(c,d,k,l) --> tmp_g_1(c,d) (coulumb)
       ! here, the coulumb and exchange parts will be equal and we thus only need to contract with the coulumb part. 

       ! now contract coulumb term over both indices into interm_cou(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex2,oindex1),&
                & nv**2,0.0E0_realk,interm_cou,nv)

       ! as the exchange contributions for the present case will be the same as the
       ! coulumb contributions, we do not need to construct these as we may include them
       ! implicitly by only adding 1*coulumb

       ! now collect in T_star array2 structure
       call daxpy(nv,-1.0E0_realk,interm_cou,1,T_star%val(:,oindex3),1)

    case(1)

       ! canAIBJ(c,d,k,l) --> tmp_g_1(c,d) (coulumb)
       ! canAIBJ(c,d,l,k) --> tmp_g_2(c,d) (exchange)

       ! now contract coulumb term over both indices into interm_cou(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex2,oindex1),&
                & nv**2,0.0E0_realk,interm_cou,nv)

       ! now contract exchange term over both indices into interm_exc(a) 1d pointer
       call dgemm('n','n',nv,1,nv**2,&
                & 1.0E0_realk,trip_ampl%val,nv,int_normal%val(:,:,oindex1,oindex2),&
                & nv**2,0.0E0_realk,interm_exc,nv)

       ! now collect in T_star array2 structure
       call daxpy(nv,-2.0E0_realk,interm_cou,1,T_star%val(:,oindex3),1)
       call daxpy(nv,1.0E0_realk,interm_exc,1,T_star%val(:,oindex3),1)

    end select TypeofContraction_12

    ! release temporary stuff
    call mem_dealloc(interm_cou)
    call mem_dealloc(interm_exc)

  end subroutine ccsdpt_contract_12


  !> brief: do the first of the two contractions over 'cdk' (here: 'cd', 'k' is the summation in driver routine)
  !         in eq. (14.6.64) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine.
  !> nv is nvirt and T_star is T_ast_1 of driver. trip_ampl is the triples amplitude array.
  !> int_virt_tile is a v^3 tile determined by driver occ index
  subroutine ccsdpt_contract_211(oindex1,oindex2,oindex3,nv,&
       & T_star,trip_ampl,int_virt_tile,special)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, nv
    type(array4), intent(inout) :: T_star
    type(array3), intent(inout) :: trip_ampl
    real(realk), dimension(nv,nv,nv), intent(in) :: int_virt_tile
    logical, intent(in) :: special
    !> temporary quantities
    integer :: contraction_type, idx
    type(array2) :: interm_cou, interm_cou_2, interm_exc
    type(array3) :: tmp_g

    ! NOTE: incoming array(4) structures are ordered according to:
    ! int_virt_tile(c,b,a,x)
    ! T_ast_1(a,b,i,j)

    ! determine which type of contraction is to be performed
    contraction_type = -1
    ! is this a special contraction, i.e., can we handle 211 and 212 contractions in one go?
    if (special) contraction_type = 0
    ! otherwise, do the default 211 contraction
    if (.not. special) contraction_type = 1

    ! contraction time (here: over virtual indices 'c' and 'd') with "coulumb minus exchange"
    ! version of canAIBC (2 * canAIBC(b,c,k,d) - canAIBC(b,d,k,c)) and (if special) canAIBC(b,c,k,d)

    ! init temporary arrays, tmp_g array3 in addition to interm_cou and interm_exc array2s
    tmp_g = array3_init_standard([nv,nv,nv])
    interm_cou = array2_init_plain([nv,nv])
    interm_exc = array2_init_plain([nv,nv])

    TypeofContraction_211: select case(contraction_type)

    case(0)

       ! note: here we collect contract over L_{dkbc} and g_{dkbc} in one go.

       ! reorder to obtain tmp_g(c,d,b)
       call array_reorder_3d(1.0E0_realk,int_virt_tile,nv,nv,nv,[1,3,2],0.0E0_realk,tmp_g%val)

       ! now contract coulumb term over 2 first indices into interm_cou(a,b) array2
       call array3_contract2(trip_ampl,tmp_g,interm_cou)

       ! reorder tmp_g to obtain exchange term, i.e., tmp_g(c,d,b) --> tmp_g(d,c,b)
       call array3_reorder(tmp_g,[2,1,3])

       ! now contract exchange term over 2 first indices into interm_exc(a,b) array2
       call array3_contract2(trip_ampl,tmp_g,interm_exc)

       ! now collect in T_star array4 structure
       call daxpy(nv**2,1.0E0_realk,interm_cou%val,1,T_star%val(:,:,oindex1,oindex2),1) 
       call daxpy(nv**2,-1.0E0_realk,interm_exc%val,1,T_star%val(:,:,oindex1,oindex2),1) 

    case(1)

       ! note: here we contract over L_{dkbc}.

       ! reorder to obtain tmp_g(c,d,b)
       call array_reorder_3d(1.0E0_realk,int_virt_tile,nv,nv,nv,[1,3,2],0.0E0_realk,tmp_g%val)

       ! now contract coulumb term over 2 first indices into interm_cou(a,b) array2
       call array3_contract2(trip_ampl,tmp_g,interm_cou)

       ! reorder tmp_g to obtain exchange term, i.e., tmp_g(c,d,b) --> tmp_g(d,c,b)
       call array3_reorder(tmp_g,[2,1,3])

       ! now contract exchange term over 2 first indices into interm_exc(a,b) array2
       call array3_contract2(trip_ampl,tmp_g,interm_exc)

       ! now collect in T_star array4 structure
       ! load in interm_cou and interm_exc as an L_{bckd}-contracted quantity
       call daxpy(nv**2,2.0E0_realk,interm_cou%val,1,T_star%val(:,:,oindex1,oindex2),1)
       call daxpy(nv**2,-1.0E0_realk,interm_exc%val,1,T_star%val(:,:,oindex1,oindex2),1)

    end select TypeofContraction_211

    ! release temporary array2s and array3s
    call array3_free(tmp_g)
    call array2_free(interm_cou)
    call array2_free(interm_exc)

  end subroutine ccsdpt_contract_211

  !> brief: do the second of the two contractions over 'cdk' (here: 'cd', 'k' is the summation in driver routine)
  !         in eq. (14.6.64) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine.
  !> nv is nvirt and T_star is T_ast_1 of driver. trip_ampl is the triples amplitude array.
  !> int_virt_tile is a v^3 tile determined by driver occ index
  subroutine ccsdpt_contract_212(oindex1,oindex2,oindex3,nv,&
       & T_star,trip_ampl,int_virt_tile)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, nv
    type(array4), intent(inout) :: T_star
    real(realk), dimension(nv,nv,nv), intent(in) :: int_virt_tile
    type(array3), intent(inout) :: trip_ampl
    !> temporary quantities
    type(array2) :: interm_cou!, interm_cou_2, interm_exc
    type(array3) :: tmp_g

    ! NOTE: incoming array(4) structures are ordered according to:
    ! int_virt_tile(c,b,a,x)
    ! T_ast_1(a,b,i,j)

    ! contraction time (here: over virtual indices 'c' and 'd') with canAIBC(b,c,k,d)

    ! init temporary tmp_g array3 structure in addition to 
    ! interm_cou array2
    tmp_g = array3_init_standard([nv,nv,nv])
    interm_cou = array2_init_plain([nv,nv])

    ! reorder to obtain tmp_g(c,d,b)
    call array_reorder_3d(1.0E0_realk,int_virt_tile,nv,nv,nv,[1,3,2],0.0E0_realk,tmp_g%val)

    ! now contract coulumb term over 2 first indices into interm_cou(_2)(a,b) array2
    call array3_contract2(trip_ampl,tmp_g,interm_cou)

    ! now collect in T_star array4 structure
    call daxpy(nv**2,-1.0E0_realk,interm_cou%val,1,T_star%val(:,:,oindex3,oindex2),1)

    ! release temporary array2s and array3s
    call array3_free(tmp_g)
    call array2_free(interm_cou)

  end subroutine ccsdpt_contract_212


  !> brief: do the first of the two contractions over 'ckl' (here: 'c', 'k' and 'l' are summations in driver routine)
  !         in eq. (14.6.64) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine.
  !> nv is nvirt and T_star is T_ast_2 of driver. trip_ampl is the triples amplitud array.
  subroutine ccsdpt_contract_221(oindex1,oindex2,oindex3,no,nv,int_occ,T_star,trip_ampl,special)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, no, nv
    type(array4), intent(inout) :: int_occ, T_star
    type(array3), intent(inout) :: trip_ampl
    logical, intent(in) :: special
    !> temporary quantities
    integer :: contraction_type, idx1
    type(array2) :: tmp_g_1, tmp_g_2
    type(array3) :: interm_cou, interm_exc, interm_cou_2

    ! NOTE: incoming array4 structures are ordered according to:
    ! canAIJK(j,c,l,k) (MEST nomenclature)
    ! T_ast_2(j,a,b,i)

    ! determine which type of contraction is to be performed
    contraction_type = -1
    ! is this a special contraction, i.e., can we handle 221 and 222 contractions in one go?
    if (special) contraction_type = 0
    ! otherwise, do the default 221 contraction
    if (.not. special) contraction_type = 1

    ! contraction time (here: over virtual index 'c') with "coulumb minus exchange"
    ! version of canAIBC (2 * canAIJK(k,j,l,c) - canAIBC(l,j,k,c)) and (if special) canAIBC(k,j,l,c)

    ! init temporary arrays, tmp_g_1 and tmp_g_2 array2s in addition to interm_cou, interm_exc, and
    ! interm_cou_2 array3s.
    tmp_g_1 = array2_init_plain([no,nv])
    tmp_g_2 = array2_init_plain([no,nv])
    interm_cou = array3_init_standard([no,nv,nv])
    interm_exc = array3_init_standard([no,nv,nv])

    TypeofContraction_221: select case(contraction_type)

    case(0)

       ! canAIJK(j,c,l,k) --> tmp_g_1(j,c) (coulumb)
       call dcopy(no*nv,int_occ%val(:,:,oindex3,oindex2),1,tmp_g_1%val,1)
       ! canAIJK(j,c,k,l) --> tmp_g_2(j,c) (exchange)
       call dcopy(no*nv,int_occ%val(:,:,oindex2,oindex3),1,tmp_g_2%val,1)

       ! now contract coulumb term over first index into interm_cou(_2)(j,a,b) array3
       ! for idx .eq. 2, interm_cou and inter_cou_2 will be equal to one another,
       ! thus we only construct interm_cou and include interm_cou_2 implicitly
       ! by only adding 1*coulumb to T_star
       call array3_contract1(trip_ampl,tmp_g_1,interm_cou,.true.,.false.)

       ! now contract exchange term over first index into interm_exc(j,a,b) array3
       call array3_contract1(trip_ampl,tmp_g_2,interm_exc,.true.,.false.)

       ! now collect in T_star array4 structure
       ! 1. load in (-1)*interm_cou
       ! 2. subtract (-1)*interm_exc
       call daxpy(no*nv**2,-1.0E0_realk,interm_cou%val,1,T_star%val(:,:,:,oindex1),1)
       call daxpy(no*nv**2,1.0E0_realk,interm_exc%val,1,T_star%val(:,:,:,oindex1),1)

    case(1)

       ! canAIJK(j,c,l,k) --> tmp_g_1(j,c) (coulumb)
       call dcopy(no*nv,int_occ%val(:,:,oindex3,oindex2),1,tmp_g_1%val,1)
       ! canAIJK(j,c,k,l) --> tmp_g_2(j,c) (exchange)
       call dcopy(no*nv,int_occ%val(:,:,oindex2,oindex3),1,tmp_g_2%val,1)
 
       ! now contract coulumb term over first index into interm_cou(_2)(j,a,b) array3
       call array3_contract1(trip_ampl,tmp_g_1,interm_cou,.true.,.false.)
 
       ! now contract exchange term over first index into interm_exc(j,a,b) array3
       call array3_contract1(trip_ampl,tmp_g_2,interm_exc,.true.,.false.)
 
       ! now collect in T_star array4 structure
       ! load in interm_cou and interm_exc as an (-1)*L_{kjlc}-contracted quantity
       call daxpy(no*nv**2,-2.0E0_realk,interm_cou%val,1,T_star%val(:,:,:,oindex1),1)
       call daxpy(no*nv**2,1.0E0_realk,interm_exc%val,1,T_star%val(:,:,:,oindex1),1)

    end select TypeofContraction_221

    ! release temporary array2s and array3s
    call array2_free(tmp_g_1)
    call array2_free(tmp_g_2)
    call array3_free(interm_cou)
    call array3_free(interm_exc)

  end subroutine ccsdpt_contract_221


  !> brief: do the second of the two contractions over 'ckl' (here: 'c', 'k' and 'l' are summations in driver routine)
  !         in eq. (14.6.64) of MEST
  !> author: Janus Juul Eriksen
  !> date: august 2012
  !> param: oindex1-oindex3 are outside loop indices of driver routine.
  !> nv is nvirt and T_star is T_ast_2 of driver. trip_ampl is the triples amplitud array.
  subroutine ccsdpt_contract_222(oindex1,oindex2,oindex3,no,nv,int_occ,T_star,trip_ampl)

    implicit none
    !> input
    integer, intent(in) :: oindex1, oindex2, oindex3, no, nv
    type(array4), intent(inout) :: int_occ, T_star
    type(array3), intent(inout) :: trip_ampl
    !> temporary quantities
    type(array2) :: tmp_g_1
    type(array3) :: interm_cou

    ! NOTE: incoming array4 structures are ordered according to:
    ! canAIJK(j,c,l,k) (MEST nomenclature)
    ! T_ast_2(j,a,b,i)

    ! contraction time (here: over virtual index 'c') with canAIBC(k,j,l,c)

    ! init temporary arrays, tmp_g_1 and tmp_g_2 array2s in addition to interm_cou, interm_exc, and
    ! interm_cou_2 array3s.
    tmp_g_1 = array2_init_plain([no,nv])
    interm_cou = array3_init_standard([no,nv,nv])


    ! canAIJK(j,c,l,k) --> tmp_g_1(j,c) (coulumb)
    call dcopy(no*nv,int_occ%val(:,:,oindex1,oindex2),1,tmp_g_1%val,1)

    ! now contract coulumb term over first index into interm_cou(_2)(j,a,b) array3
    call array3_contract1(trip_ampl,tmp_g_1,interm_cou,.true.,.false.)


    ! now collect in T_star array4 structure
    call daxpy(no*nv**2,1.0E0_realk,interm_cou%val,1,T_star%val(:,:,:,oindex3),1)


    ! release temporary array2s and array3s
    call array2_free(tmp_g_1)
    call array3_free(interm_cou)

  end subroutine ccsdpt_contract_222


  !> \brief: calculate E[5] contribution to single fragment ccsd(t) energy correction
  !> \author: Janus Eriksen
  !> \date: september 2012
  subroutine ccsdpt_energy_e5_frag(MyFragment,ccsd_singles,ccsdpt_singles)

    implicit none

    !> fragment info
    type(ccatom), intent(inout) :: MyFragment
    ! ccsd and ccsd(t) singles amplitudes
    type(array2), intent(inout) :: ccsd_singles, ccsdpt_singles
    !> integers
    integer :: nocc_eos, nvirt_eos, i,a, i_eos, a_eos
    !> temp energy
    real(realk) :: energy_tmp, ccsdpt_e5

    ! init dimensions
    nocc_eos = MyFragment%noccEOS
    nvirt_eos = MyFragment%nunoccEOS

    ! ***********************
    !   do E[5] energy part
    ! ***********************

    ! init energy reals to be on the safe side.
    ! note: OccEnergyPT and VirtEnergyPT have been initialized in the e4 routine.
    MyFragment%energies(12) = 0.0E0_realk
    MyFragment%energies(13) = 0.0E0_realk

    ! init temp energy
    ccsdpt_e5 = 0.0E0_realk

                    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,i_eos,a,a_eos,energy_tmp),&
                    !$OMP& SHARED(ccsd_singles,ccsdpt_singles,nocc_eos,nvirt_eos,MyFragment),&
                    !$OMP& REDUCTION(+:ccsdpt_e5)
  ido_frag_singles: do i=1,nocc_eos
                    i_eos = MyFragment%idxo(i)
     ado_frag_singles: do a=1,nvirt_eos
                       a_eos = MyFragment%idxu(a)

                          energy_tmp = ccsd_singles%val(a_eos,i_eos) * ccsdpt_singles%val(a_eos,i_eos)
                          ccsdpt_e5 = ccsdpt_e5 + energy_tmp

                       end do ado_frag_singles
                    end do ido_frag_singles
                    !$OMP END PARALLEL DO

    MyFragment%energies(12) = 2.0E0_realk * ccsdpt_e5

    ! insert into occ. part. scheme part
    MyFragment%energies(8) = MyFragment%energies(8) + MyFragment%energies(12)

    ! *********************************
    ! do unoccupied partitioning scheme
    ! *********************************

    ! singles contribution is the same as in occupied partitioning scheme
    MyFragment%energies(9) = MyFragment%energies(9) + MyFragment%energies(12)
    ! insert into virt_e5 part
    MyFragment%energies(13) = MyFragment%energies(13) + MyFragment%energies(12)

    ! ******************************
    !   done with E[5] energy part
    ! ******************************

  end subroutine ccsdpt_energy_e5_frag 


  !> \brief: calculate E[5] contribution to pair fragment ccsd(t) energy correction
  !> \author: Janus Eriksen
  !> \date: september 2012
  subroutine ccsdpt_energy_e5_pair(Fragment1,Fragment2,PairFragment,ccsd_singles,ccsdpt_singles)

    implicit none

    !> fragment # 1 in the pair fragment
    type(ccatom),intent(inout) :: Fragment1
    !> fragment # 2 in the pair fragment
    type(ccatom),intent(inout) :: Fragment2
    !> fragment info
    type(ccatom), intent(inout) :: PairFragment
    ! ccsd and ccsd(t) singles amplitudes
    type(array2), intent(inout) :: ccsd_singles, ccsdpt_singles
    !> integers
    integer :: nocc_eos, nvirt_eos, i, a, idx, adx, AtomI, AtomA, i_eos, a_eos
    !> logicals to avoid double counting
    logical :: occ_in_frag_1, virt_in_frag_1, occ_in_frag_2, virt_in_frag_2

    ! init dimensions
    nocc_eos = PairFragment%noccEOS
    nvirt_eos = PairFragment%nunoccEOS

    ! ***********************
    !   do E[5] energy part
    ! ***********************

    ! init energy reals to be on the safe side.
    ! note: OccEnergyPT and VirtEnergyPT have been initialized in the e4 routine.
    PairFragment%energies(12) = 0.0E0_realk
    PairFragment%energies(13) = 0.0E0_realk

  ido_pair_singles: do i=1,nocc_eos
                    i_eos = PairFragment%idxo(i)
                    AtomI = PairFragment%occAOSorb(i_eos)%CentralAtom
     ado_pair_singles: do a=1,nvirt_eos
                       a_eos = PairFragment%idxu(a)
                       AtomA = PairFragment%unoccAOSorb(a_eos)%CentralAtom

                       ! occ in frag # 1, virt in frag # 2

                          occ_in_frag_1 = .false.
                          do idx = 1,Fragment1%nEOSatoms
                             if (Fragment1%EOSatoms(idx) .eq. AtomI) then
                                occ_in_frag_1 = .true.
                             end if
                          end do

                          virt_in_frag_2 = .false.
                          do adx = 1,Fragment2%nEOSatoms
                             if (Fragment2%EOSatoms(adx) .eq. AtomA) then
                                virt_in_frag_2 = .true.
                             end if
                          end do

                          if (occ_in_frag_1 .and. virt_in_frag_2) then
                             PairFragment%energies(12) = PairFragment%energies(12) &
                               & + 2.0E0_realk * ccsd_singles%val(a_eos,i_eos) &
                               & * ccsdpt_singles%val(a_eos,i_eos)
                          end if

                       ! virt in frag # 1, occ in frag # 2
                            
                          occ_in_frag_2 = .false. 
                          do idx = 1,Fragment2%nEOSatoms
                             if (Fragment2%EOSatoms(idx) .eq. AtomI) then
                                occ_in_frag_2 = .true.
                             end if
                          end do 
                             
                          virt_in_frag_1 = .false.
                          do adx = 1,Fragment1%nEOSatoms
                             if (Fragment1%EOSatoms(adx) .eq. AtomA) then
                                virt_in_frag_1 = .true.
                             end if
                          end do
                             
                          if (occ_in_frag_2 .and. virt_in_frag_1) then
                             PairFragment%energies(12) = PairFragment%energies(12) &
                               & + 2.0E0_realk * ccsd_singles%val(a_eos,i_eos) &
                               & * ccsdpt_singles%val(a_eos,i_eos)
                          end if

                       ! sanity checks

                          if (.not. (occ_in_frag_1 .or. occ_in_frag_2)) then
                             call lsquit('Problem in evaluation of E[5] contr. &
                                  & to pair fragment energy: occ orbital neither in frag 1 or 2',DECinfo%output)        
                          end if
                          if (.not. (virt_in_frag_1 .or. virt_in_frag_2)) then
                             call lsquit('Problem in evaluation of E[5] contr. &
                                  & to pair fragment energy: virt orbital neither in frag 1 or 2',DECinfo%output)
                          end if
                          if (occ_in_frag_1 .and. occ_in_frag_2) then
                             call lsquit('Problem in evaluation of E[5] contr. &
                                  & to pair fragment energy: occ orbital both in frag 1 or 2',DECinfo%output)
                          end if
                          if (virt_in_frag_1 .and. virt_in_frag_2) then
                             call lsquit('Problem in evaluation of E[5] contr. &
                                  & to pair fragment energy: virt orbital both in frag 1 or 2',DECinfo%output)
                          end if

                       end do ado_pair_singles
                    end do ido_pair_singles

    ! insert into occ. part. scheme part
    PairFragment%energies(8) = PairFragment%energies(8) + PairFragment%energies(12)

    ! *********************************
    ! do unoccupied partitioning scheme
    ! *********************************

    ! singles contribution is the same as in occupied partitioning scheme
    PairFragment%energies(9) = PairFragment%energies(9) + PairFragment%energies(12)
    ! insert into virt_e5 part
    PairFragment%energies(13) = PairFragment%energies(13) + PairFragment%energies(12)

    ! ******************************
    !   done with E[5] energy part
    ! ******************************

  end subroutine ccsdpt_energy_e5_pair


  !> \brief: calculate E[4] contribution to single fragment ccsd(t) energy correction
  !> \author: Janus Eriksen
  !> \date: september 2012
  subroutine ccsdpt_energy_e4_frag(MyFragment,ccsd_doubles,ccsdpt_doubles,&
                             & occ_contribs,virt_contribs,fragopt_pT)

    implicit none

    !> fragment info
    type(ccatom), intent(inout) :: MyFragment
    ! ccsd and ccsd(t) doubles amplitudes
    type(array4), intent(inout) :: ccsd_doubles, ccsdpt_doubles
    !> is this called from inside the ccsd(t) fragment optimization routine?
    logical, optional, intent(in) :: fragopt_pT
    !> incomming orbital contribution vectors
    real(realk), intent(inout) :: occ_contribs(MyFragment%noccAOS), virt_contribs(MyFragment%nunoccAOS)
    !> integers
    integer :: nocc_eos, nocc_aos, nvirt_eos, nvirt_aos, i,j,a,b, i_eos, j_eos, a_eos, b_eos
    !> energy reals
    real(realk) :: energy_tmp, energy_res_cou, energy_res_exc

    ! init dimensions
    nocc_eos = MyFragment%noccEOS
    nvirt_eos = MyFragment%nunoccEOS
    nocc_aos = MyFragment%noccAOS
    nvirt_aos = MyFragment%nunoccAOS

    ! **************************************************************
    ! ************** do energy for single fragment *****************
    ! **************************************************************

    ! ***********************
    !   do E[4] energy part
    ! ***********************

    ! init energy reals to be on the safe side
    ! note: OccEnergyPT and VirtEnergyPT is also initialized from in here
    !       as this (e4) routine is called before the e5 routine
    MyFragment%energies(8) = 0.0E0_realk
    MyFragment%energies(9) = 0.0E0_realk
    MyFragment%energies(10) = 0.0E0_realk
    MyFragment%energies(11) = 0.0E0_realk

    ! *******************************
    ! do occupied partitioning scheme
    ! *******************************

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,i_eos,j,j_eos,a,b,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nocc_eos,nvirt_aos,MyFragment),&
                        !$OMP& REDUCTION(+:energy_res_cou),REDUCTION(+:virt_contribs)
  jdo_frag_doubles_cou: do j=1,nocc_eos
                        j_eos = MyFragment%idxo(j)
     ido_frag_doubles_cou: do i=1,nocc_eos
                           i_eos = MyFragment%idxo(i)

                              do b=1,nvirt_aos
                                 do a=1,nvirt_aos

                                    energy_tmp = 4.0E0_realk * ccsd_doubles%val(a,b,i_eos,j_eos) &
                                                   & * ccsdpt_doubles%val(a,b,i_eos,j_eos)
                                    energy_res_cou = energy_res_cou + energy_tmp

                                    ! update contribution from aos orbital a
                                    virt_contribs(a) = virt_contribs(a) + energy_tmp

                                    ! update contribution from aos orbital b 
                                    ! (only if different from aos orbital a to avoid double counting)
                                    if (a .ne. b) virt_contribs(b) = virt_contribs(b) + energy_tmp

                                 end do
                              end do

                           end do ido_frag_doubles_cou
                        end do jdo_frag_doubles_cou
                        !$OMP END PARALLEL DO

    ! reorder from (a,b,i,j) to (a,b,j,i)
    call array4_reorder(ccsd_doubles,[1,2,4,3])

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,i_eos,j,j_eos,a,b,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nocc_eos,nvirt_aos,MyFragment),&
                        !$OMP& REDUCTION(+:energy_res_exc),REDUCTION(+:virt_contribs)
  jdo_frag_doubles_exc: do j=1,nocc_eos
                        j_eos = MyFragment%idxo(j)
     ido_frag_doubles_exc: do i=1,nocc_eos
                           i_eos = MyFragment%idxo(i)

                              do b=1,nvirt_aos
                                 do a=1,nvirt_aos

                                    energy_tmp = 2.0E0_realk * ccsd_doubles%val(a,b,i_eos,j_eos) &
                                                   & * ccsdpt_doubles%val(a,b,i_eos,j_eos)
                                    energy_res_exc = energy_res_exc - energy_tmp

                                    ! update contribution from aos orbital a
                                    virt_contribs(a) = virt_contribs(a) - energy_tmp

                                    ! update contribution from aos orbital b 
                                    ! (only if different from aos orbital a to avoid double counting)
                                    if (a .ne. b) virt_contribs(b) = virt_contribs(b) - energy_tmp

                                 end do
                              end do

                           end do ido_frag_doubles_exc
                        end do jdo_frag_doubles_exc
                        !$OMP END PARALLEL DO

    !get total fourth--order energy contribution
    MyFragment%energies(10) = energy_res_cou + energy_res_exc

    ! insert into occ. part. scheme part
    MyFragment%energies(8) = MyFragment%energies(8) + MyFragment%energies(10)

    ! *********************************
    ! do unoccupied partitioning scheme
    ! *********************************

    ! initially, reorder ccsd_doubles and ccsdpt_doubles
    ! ccsd_doubles from from (a,b,j,i) sequence to (j,i,a,b) sequence
    ! ccsdpt_doubles from from (a,b,i,j) sequence to (i,j,a,b) sequence
    call array4_reorder(ccsd_doubles,[3,4,1,2])
    call array4_reorder(ccsdpt_doubles,[3,4,1,2])

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(a,a_eos,b,b_eos,i,j,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nvirt_eos,nocc_aos,MyFragment),&
                        !$OMP& REDUCTION(+:energy_res_exc),REDUCTION(+:occ_contribs)
  bdo_frag_doubles_exc: do b=1,nvirt_eos
                        b_eos = MyFragment%idxu(b)
     ado_frag_doubles_exc: do a=1,nvirt_eos
                           a_eos = MyFragment%idxu(a)

                              do j=1,nocc_aos
                                 do i=1,nocc_aos

                                    energy_tmp = 2.0E0_realk * ccsd_doubles%val(i,j,a_eos,b_eos) &
                                                   & * ccsdpt_doubles%val(i,j,a_eos,b_eos)
                                    energy_res_exc = energy_res_exc - energy_tmp

                                    ! update contribution from aos orbital i
                                    occ_contribs(i) = occ_contribs(i) - energy_tmp

                                    ! update contribution from aos orbital j 
                                    ! (only if different from aos orbital i to avoid double counting)
                                    if (i .ne. j) occ_contribs(j) = occ_contribs(j) - energy_tmp

                                 end do
                              end do

                           end do ado_frag_doubles_exc
                        end do bdo_frag_doubles_exc
                        !$OMP END PARALLEL DO

    ! reorder form (j,i,a,b) to (i,j,a,b)
    call array4_reorder(ccsd_doubles,[2,1,3,4])

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(a,a_eos,b,b_eos,i,j,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nvirt_eos,nocc_aos,MyFragment),&
                        !$OMP& REDUCTION(+:energy_res_cou),REDUCTION(+:occ_contribs)
  bdo_frag_doubles_cou: do b=1,nvirt_eos
                        b_eos = MyFragment%idxu(b)
     ado_frag_doubles_cou: do a=1,nvirt_eos
                           a_eos = MyFragment%idxu(a)

                              do j=1,nocc_aos
                                 do i=1,nocc_aos

                                    energy_tmp = 4.0E0_realk * ccsd_doubles%val(i,j,a_eos,b_eos) &
                                                   & * ccsdpt_doubles%val(i,j,a_eos,b_eos)
                                    energy_res_cou = energy_res_cou + energy_tmp

                                    ! update contribution from aos orbital i
                                    occ_contribs(i) = occ_contribs(i) + energy_tmp

                                    ! update contribution from aos orbital j 
                                    ! (only if different from aos orbital i to avoid double counting)
                                    if (i .ne. j) occ_contribs(j) = occ_contribs(j) + energy_tmp

                                 end do
                              end do

                           end do ado_frag_doubles_cou
                        end do bdo_frag_doubles_cou
                        !$OMP END PARALLEL DO

    !get total fourth--order energy contribution
    MyFragment%energies(11) = energy_res_cou + energy_res_exc

    ! insert into virt. part. scheme part
    MyFragment%energies(9) = MyFragment%energies(9) + MyFragment%energies(11)

    ! ******************************
    !   done with E[4] energy part
    ! ******************************

    ! ************************************************************************
    !   as we need to reuse the ccsd doubles in the fragment optimization,
    !   we here reorder back into (a,i,b,j) sequence IF fragopt_pT == .true. 
    ! ************************************************************************

    if (present(fragopt_pT)) then

       ! reorder from (i,j,a,b) to (a,i,b,j)
       if (fragopt_pT) call array4_reorder(ccsd_doubles,[3,1,4,2])

    end if

    ! *******************************************************************
    ! ************** done w/ energy for single fragment *****************
    ! *******************************************************************

  end subroutine ccsdpt_energy_e4_frag


  !> \brief: calculate E[4] contribution to pair fragment ccsd(t) energy correction
  !> \author: Janus Eriksen
  !> \date: september 2012
  subroutine ccsdpt_energy_e4_pair(Fragment1,Fragment2,PairFragment,ccsd_doubles,ccsdpt_doubles)

    implicit none

    !> fragment # 1 in the pair fragment
    type(ccatom),intent(inout) :: Fragment1
    !> fragment # 2 in the pair fragment
    type(ccatom),intent(inout) :: Fragment2
    !> pair fragment info
    type(ccatom), intent(inout) :: PairFragment
    ! ccsd and ccsd(t) doubles amplitudes
    type(array4), intent(inout) :: ccsd_doubles, ccsdpt_doubles
    ! logical pointers for keeping hold of which pairs are to be handled
    logical, pointer :: dopair_occ(:,:), dopair_virt(:,:)
    !> integers
    integer :: nocc_eos, nocc_aos, nvirt_eos, nvirt_aos, i,j,a,b, i_eos, j_eos, a_eos, b_eos
    !> temporary energy arrays
    type(array2) :: energy_interm_cou, energy_interm_exc, energy_interm_ccsdpt
    !> energy reals
    real(realk) :: energy_tmp, energy_res_cou, energy_res_exc  

    ! init dimensions
    nocc_eos = PairFragment%noccEOS
    nvirt_eos = PairFragment%nunoccEOS
    nocc_aos = PairFragment%noccAOS
    nvirt_aos = PairFragment%nunoccAOS

    ! which pairs are to be included for occ and unocc space (avoid double counting)
    call mem_alloc(dopair_occ,nocc_eos,nocc_eos)
    call mem_alloc(dopair_virt,nvirt_eos,nvirt_eos)
    call which_pairs_occ(Fragment1,Fragment2,PairFragment,dopair_occ)
    call which_pairs_unocc(Fragment1,Fragment2,PairFragment,dopair_virt)

    ! *************************************************************
    ! ************** do energy for pair fragments *****************
    ! *************************************************************

    ! ***********************
    !   do E[4] energy part
    ! ***********************

    ! init energy reals to be on the safe side
    ! note: OccEnergyPT and VirtEnergyPT is also initialized from in here
    !       as this (e4) routine is called before the e5 routine
    PairFragment%energies(8) = 0.0E0_realk
    PairFragment%energies(9) = 0.0E0_realk
    PairFragment%energies(10) = 0.0E0_realk
    PairFragment%energies(11) = 0.0E0_realk

    ! *******************************
    ! do occupied partitioning scheme
    ! *******************************

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,i_eos,j,j_eos,a,b,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nocc_eos,nvirt_aos,&
                        !$OMP& PairFragment,dopair_occ),REDUCTION(+:energy_res_cou)
  jdo_pair_doubles_cou: do j=1,nocc_eos
                        j_eos = PairFragment%idxo(j)
     ido_pair_doubles_cou: do i=1,nocc_eos
                           i_eos = PairFragment%idxo(i)

                              if (.not. dopair_occ(i,j)) cycle ido_pair_doubles_cou

                              do b=1,nvirt_aos
                                 do a=1,nvirt_aos

                                    energy_tmp = ccsd_doubles%val(a,b,i_eos,j_eos) &
                                               & * ccsdpt_doubles%val(a,b,i_eos,j_eos)
                                    energy_res_cou = energy_res_cou + energy_tmp

                                 end do
                              end do

                           end do ido_pair_doubles_cou
                        end do jdo_pair_doubles_cou
                        !$OMP END PARALLEL DO

    ! reorder from (a,b,i,j) to (a,b,j,i)
    call array4_reorder(ccsd_doubles,[1,2,4,3])

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,i_eos,j,j_eos,a,b,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nocc_eos,nvirt_aos,&
                        !$OMP& PairFragment,dopair_occ),REDUCTION(+:energy_res_exc)
  jdo_pair_doubles_exc: do j=1,nocc_eos
                        j_eos = PairFragment%idxo(j)
     ido_pair_doubles_exc: do i=1,nocc_eos
                           i_eos = PairFragment%idxo(i)

                              if (.not. dopair_occ(i,j)) cycle ido_pair_doubles_exc

                              do b=1,nvirt_aos
                                 do a=1,nvirt_aos

                                    energy_tmp = ccsd_doubles%val(a,b,i_eos,j_eos) &
                                               & * ccsdpt_doubles%val(a,b,i_eos,j_eos)
                                    energy_res_exc = energy_res_exc + energy_tmp

                                 end do
                              end do

                           end do ido_pair_doubles_exc
                        end do jdo_pair_doubles_exc
                        !$OMP END PARALLEL DO

    ! get total fourth--order energy contribution
    PairFragment%energies(10) = 4.0E0_realk * energy_res_cou - 2.0E0_realk * energy_res_exc

    ! insert into occ. part. scheme part
    PairFragment%energies(8) = PairFragment%energies(8) + PairFragment%energies(10)

    ! *********************************
    ! do unoccupied partitioning scheme
    ! *********************************

    ! initially, reorder ccsd_doubles and ccsdpt_doubles
    ! ccsd_doubles from from (a,b,j,i) sequence to (j,i,a,b) sequence
    ! ccsdpt_doubles from from (a,b,i,j) sequence to (i,j,a,b) sequence
    call array4_reorder(ccsd_doubles,[3,4,1,2])
    call array4_reorder(ccsdpt_doubles,[3,4,1,2])

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(a,a_eos,b,b_eos,i,j,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nvirt_eos,nocc_aos,&
                        !$OMP& PairFragment,dopair_virt),REDUCTION(+:energy_res_exc)
  bdo_pair_doubles_exc: do b=1,nvirt_eos
                        b_eos = PairFragment%idxu(b)
     ado_pair_doubles_exc: do a=1,nvirt_eos
                           a_eos = PairFragment%idxu(a)

                              if (.not. dopair_virt(a,b)) cycle ado_pair_doubles_exc
    
                              do j=1,nocc_aos
                                 do i=1,nocc_aos

                                    energy_tmp = ccsd_doubles%val(i,j,a_eos,b_eos) &
                                               & * ccsdpt_doubles%val(i,j,a_eos,b_eos)
                                    energy_res_exc = energy_res_exc + energy_tmp

                                 end do
                              end do
    
                           end do ado_pair_doubles_exc
                        end do bdo_pair_doubles_exc
                        !$OMP END PARALLEL DO

    ! reorder form (j,i,a,b) to (i,j,a,b)
    call array4_reorder(ccsd_doubles,[2,1,3,4])

                        !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(a,a_eos,b,b_eos,i,j,energy_tmp),&
                        !$OMP& SHARED(ccsd_doubles,ccsdpt_doubles,nvirt_eos,nocc_aos,&
                        !$OMP& PairFragment,dopair_virt),REDUCTION(+:energy_res_cou)
  bdo_pair_doubles_cou: do b=1,nvirt_eos
                        b_eos = PairFragment%idxu(b)
     ado_pair_doubles_cou: do a=1,nvirt_eos
                           a_eos = PairFragment%idxu(a)

                              if (.not. dopair_virt(a,b)) cycle ado_pair_doubles_cou

                              do j=1,nocc_aos
                                 do i=1,nocc_aos

                                    energy_tmp = ccsd_doubles%val(i,j,a_eos,b_eos) &
                                               & * ccsdpt_doubles%val(i,j,a_eos,b_eos)
                                    energy_res_cou = energy_res_cou + energy_tmp

                                 end do
                              end do

                           end do ado_pair_doubles_cou
                        end do bdo_pair_doubles_cou
                        !$OMP END PARALLEL DO

    ! get total fourth--order energy contribution
    PairFragment%energies(11) = 4.0E0_realk * energy_res_cou - 2.0E0_realk * energy_res_exc

    ! insert into virt. part. scheme part
    PairFragment%energies(9) = PairFragment%energies(9) + PairFragment%energies(11)

    ! ******************************
    !   done with E[4] energy part
    ! ******************************

    ! now release logical pair arrays
    call mem_dealloc(dopair_occ)
    call mem_dealloc(dopair_virt)

    ! ******************************************************************
    ! ************** done w/ energy for pair fragments *****************
    ! ******************************************************************

  end subroutine ccsdpt_energy_e4_pair

  !> \brief: calculate E[4] contribution to ccsd(t) energy correction for full molecule calculation
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine ccsdpt_energy_e4_full(nocc,nvirt,natoms,offset,ccsd_doubles,ccsdpt_doubles,occ_orbitals,&
                           & eccsdpt_matrix_cou,eccsdpt_matrix_exc,ccsdpt_e4)

    implicit none

    !> ccsd and ccsd(t) doubles amplitudes
    type(array4), intent(inout) :: ccsd_doubles, ccsdpt_doubles
    !> dimensions
    integer, intent(in) :: nocc, nvirt, natoms, offset
    !> occupied orbital information
    type(ccorbital), dimension(nocc+offset), intent(inout) :: occ_orbitals
    !> etot
    real(realk), intent(inout) :: ccsdpt_e4
    real(realk), dimension(natoms,natoms), intent(inout) :: eccsdpt_matrix_cou, eccsdpt_matrix_exc
    !> integers
    integer :: i,j,a,b,atomI,atomJ
    !> energy reals
    real(realk) :: energy_tmp, energy_res_cou, energy_res_exc

    ! *************************************************************
    ! ************** do energy for full molecule ******************
    ! *************************************************************

    ! ***********************
    !   do E[4] energy part
    ! ***********************

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk
    ccsdpt_e4 = 0.0E0_realk

    ! ***note: we only run over nval (which might be equal to nocc_tot if frozencore = .false.)
    ! so we only assign orbitals for the space in which the core orbitals (the offset) are omited

    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,atomI,j,atomJ,a,b,energy_tmp),REDUCTION(+:energy_res_cou),&
    !$OMP& REDUCTION(+:eccsdpt_matrix_cou),SHARED(ccsd_doubles,ccsdpt_doubles,nocc,nvirt,occ_orbitals,offset)
    do j=1,nocc
    atomJ = occ_orbitals(j+offset)%CentralAtom
       do i=1,nocc
       atomI = occ_orbitals(i+offset)%CentralAtom

          do b=1,nvirt
             do a=1,nvirt

                energy_tmp = ccsd_doubles%val(a,b,i,j) * ccsdpt_doubles%val(a,b,i,j)
                eccsdpt_matrix_cou(AtomI,AtomJ) = eccsdpt_matrix_cou(AtomI,AtomJ) + energy_tmp
                energy_res_cou = energy_res_cou + energy_tmp

             end do
          end do

       end do
    end do
    !$OMP END PARALLEL DO

    ! reorder from (a,b,i,j) to (a,b,j,i)
    call array4_reorder(ccsd_doubles,[1,2,4,3])

    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,atomI,j,atomJ,a,b,energy_tmp),REDUCTION(+:energy_res_exc),&
    !$OMP& REDUCTION(+:eccsdpt_matrix_exc),SHARED(ccsd_doubles,ccsdpt_doubles,nocc,nvirt,occ_orbitals,offset)
    do j=1,nocc
    atomJ = occ_orbitals(j+offset)%CentralAtom
       do i=1,nocc
       atomI = occ_orbitals(i+offset)%CentralAtom

          do b=1,nvirt
             do a=1,nvirt

                energy_tmp = ccsd_doubles%val(a,b,i,j) * ccsdpt_doubles%val(a,b,i,j)
                eccsdpt_matrix_exc(AtomI,AtomJ) = eccsdpt_matrix_exc(AtomI,AtomJ) + energy_tmp
                energy_res_exc = energy_res_exc + energy_tmp

             end do
          end do

       end do
    end do
    !$OMP END PARALLEL DO

    ! get total fourth--order energy contribution
    eccsdpt_matrix_cou = 4.0E0_realk * eccsdpt_matrix_cou - 2.0E0_realk * eccsdpt_matrix_exc
    ccsdpt_e4 = 4.0E0_realk * energy_res_cou - 2.0E0_realk * energy_res_exc

    ! for the e4 pair fragment energy matrix,
    ! we only consider pairs IJ where J>I; thus, move contributions

    do AtomJ=1,natoms
       do AtomI=AtomJ+1,natoms

          eccsdpt_matrix_cou(AtomI,AtomJ) = eccsdpt_matrix_cou(AtomI,AtomJ) &
                                              & + eccsdpt_matrix_cou(AtomJ,AtomI)
       end do
    end do



    ! ******************************************************************
    ! ************** done w/ energy for full molecule ******************
    ! ******************************************************************

  end subroutine ccsdpt_energy_e4_full

  !> \brief: print out E[4] fragment and pair interaction contribution to 
  !>         ccsd(t) energy correction for full molecule calculation
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine print_e4_full(natoms,e4_matrix,orbitals_assigned,distance_table)

    implicit none

    !> number of atoms in molecule
    integer, intent(in) :: natoms
    !> matrices containing E[4] energies and interatomic distances
    real(realk), dimension(natoms,natoms), intent(inout) :: e4_matrix, distance_table
    !> vector handling how the orbitals are assigned?
    logical, dimension(natoms), intent(inout) :: orbitals_assigned
    !> loop counters
    integer :: i,j
    real(realk), parameter :: bohr_to_angstrom = 0.5291772083E0_realk

    ! print out fragment energies

    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,'(1X,a)') '*                         E[4] energies                       *'
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(8X,a)') '-- Atomic fragment energies (fourth--order E[4])'
    write(DECinfo%output,'(8X,a)') '------    --------------------'
    write(DECinfo%output,'(8X,a)') ' Atom            Energy '
    write(DECinfo%output,'(8X,a)') '------    --------------------'
    write(DECinfo%output,*)

    do i=1,natoms

       if (orbitals_assigned(i)) then

          write(DECinfo%output,'(1X,a,i6,4X,g20.10)') '#SING#', i, e4_matrix(i,i)

       end if

    end do

    ! now print out pair interaction energies

    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(8X,a)') '-- Pair interaction energies (fourth--order E[4])     '
    write(DECinfo%output,'(8X,a)') '------    ------    ----------    --------------------'
    write(DECinfo%output,'(8X,a)') '   P         Q        R(Ang)              E(PQ)       '
    write(DECinfo%output,'(8X,a)') '------    ------    ----------    --------------------'
    write(DECinfo%output,*)

    do j=1,natoms
       do i=j+1,natoms

          ! write increments only if pair interaction energy is nonzero
          if( orbitals_assigned(i) .and. orbitals_assigned(j) ) then

             write(DECinfo%output,'(1X,a,i6,4X,i6,4X,g10.4,4X,g20.10)') '#PAIR#',j,i,&
                  & bohr_to_angstrom*distance_table(i,j), e4_matrix(i,j)

          end if

       end do
    end do


  end subroutine print_e4_full

  !> \brief: calculate ccsd correlation energy for full molecule calculation
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine ccsd_energy_full(nocc,nvirt,natoms,offset,ccsd_doubles,ccsd_singles,integral,occ_orbitals,&
                           & eccsdpt_matrix_cou,eccsdpt_matrix_exc)

    implicit none

    !> ccsd doubles amplitudes and VOVO integrals (ordered as (a,b,i,j))
    type(array4), intent(inout) :: ccsd_doubles, integral
    !> ccsd singles amplitudes
    type(array2), intent(inout) :: ccsd_singles
    !> dimensions
    integer, intent(in) :: nocc, nvirt, natoms, offset
    !> occupied orbital information
    type(ccorbital), dimension(nocc+offset), intent(inout) :: occ_orbitals
    !> etot
    real(realk), dimension(natoms,natoms), intent(inout) :: eccsdpt_matrix_cou, eccsdpt_matrix_exc
    !> integers
    integer :: i,j,a,b,atomI,atomJ
    !> energy reals
    real(realk) :: energy_tmp_1, energy_tmp_2, energy_res_cou, energy_res_exc

    ! *************************************************************
    ! ************** do energy for full molecule ******************
    ! *************************************************************

    ! ***********************
    !   do CCSD energy part
    ! ***********************

    energy_res_cou = 0.0E0_realk
    energy_res_exc = 0.0E0_realk

    ! ***note: we only run over nval (which might be equal to nocc_tot if frozencore = .false.)
    ! so we only assign orbitals for the space in which the core orbitals (the offset) are omited

    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,atomI,j,atomJ,a,b,energy_tmp_1,energy_tmp_2),&
    !$OMP& REDUCTION(+:energy_res_cou),REDUCTION(+:eccsdpt_matrix_cou),&
    !$OMP& SHARED(ccsd_doubles,ccsd_singles,integral,nocc,nvirt,occ_orbitals,offset)
    do j=1,nocc
    atomJ = occ_orbitals(j+offset)%CentralAtom
       do i=1,nocc
       atomI = occ_orbitals(i+offset)%CentralAtom

          do b=1,nvirt
             do a=1,nvirt

                energy_tmp_1 = ccsd_doubles%val(a,b,i,j) * integral%val(a,b,i,j)
                energy_tmp_2 = ccsd_singles%val(a,i) * ccsd_singles%val(b,j) * integral%val(a,b,i,j)
                eccsdpt_matrix_cou(AtomI,AtomJ) = eccsdpt_matrix_cou(AtomI,AtomJ) &
                                        & + energy_tmp_1 + energy_tmp_2

             end do
          end do

       end do
    end do
    !$OMP END PARALLEL DO

    ! reorder from (a,b,i,j) to (a,b,j,i)
    call array4_reorder(integral,[1,2,4,3])

    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,atomI,j,atomJ,a,b,energy_tmp_1,energy_tmp_2),&
    !$OMP& REDUCTION(+:energy_res_exc),REDUCTION(+:eccsdpt_matrix_exc),&
    !$OMP& SHARED(ccsd_doubles,ccsd_singles,integral,nocc,nvirt,occ_orbitals,offset)
    do j=1,nocc
    atomJ = occ_orbitals(j+offset)%CentralAtom
       do i=1,nocc
       atomI = occ_orbitals(i+offset)%CentralAtom

          do b=1,nvirt
             do a=1,nvirt

                energy_tmp_1 = ccsd_doubles%val(a,b,i,j) * integral%val(a,b,i,j)
                energy_tmp_2 = ccsd_singles%val(a,i) * ccsd_singles%val(b,j) * integral%val(a,b,i,j)
                eccsdpt_matrix_exc(AtomI,AtomJ) = eccsdpt_matrix_exc(AtomI,AtomJ) &
                                        & + energy_tmp_1 + energy_tmp_2

             end do
          end do

       end do
    end do
    !$OMP END PARALLEL DO

    ! get total fourth--order energy contribution
    eccsdpt_matrix_cou = 2.0E0_realk * eccsdpt_matrix_cou - eccsdpt_matrix_exc

    ! for the pair fragment energy matrix,
    ! we only consider pairs IJ where J>I; thus, move contributions

    do AtomJ=1,natoms
       do AtomI=AtomJ+1,natoms

          eccsdpt_matrix_cou(AtomI,AtomJ) = eccsdpt_matrix_cou(AtomI,AtomJ) &
                                              & + eccsdpt_matrix_cou(AtomJ,AtomI)
       end do
    end do


    ! ******************************************************************
    ! ************** done w/ energy for full molecule ******************
    ! ******************************************************************

  end subroutine ccsd_energy_full


  !> \brief: print out CCSD fragment and pair interaction energies for full molecule calculation 
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine print_ccsd_full(natoms,ccsd_matrix,orbitals_assigned,distance_table)

    implicit none

    !> number of atoms in molecule
    integer, intent(in) :: natoms
    !> matrices containing E[4] energies and interatomic distances
    real(realk), dimension(natoms,natoms), intent(inout) :: ccsd_matrix, distance_table
    !> vector handling how the orbitals are assigned?
    logical, dimension(natoms), intent(inout) :: orbitals_assigned
    !> loop counters
    integer :: i,j
    real(realk), parameter :: bohr_to_angstrom = 0.5291772083E0_realk

    ! print out fragment energies

    write(DECinfo%output,*)
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,'(1X,a)') '*                         CCSD energies                       *'
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(8X,a)') '-- Atomic fragment energies (CCSD)'
    write(DECinfo%output,'(8X,a)') '------    --------------------'
    write(DECinfo%output,'(8X,a)') ' Atom            Energy '
    write(DECinfo%output,'(8X,a)') '------    --------------------'
    write(DECinfo%output,*)

    do i=1,natoms

       if (orbitals_assigned(i)) then

          write(DECinfo%output,'(1X,a,i6,4X,g20.10)') '#SING#', i, ccsd_matrix(i,i)

       end if

    end do

    ! now print out pair interaction energies

    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(8X,a)') '-- Pair interaction energies (CCSD)                   '
    write(DECinfo%output,'(8X,a)') '------    ------    ----------    --------------------'
    write(DECinfo%output,'(8X,a)') '   P         Q        R(Ang)              E(PQ)       '
    write(DECinfo%output,'(8X,a)') '------    ------    ----------    --------------------'
    write(DECinfo%output,*)
    write(DECinfo%output,*)

    do j=1,natoms
       do i=j+1,natoms

          ! write increments only if pair interaction energy is nonzero
          if( orbitals_assigned(i) .and. orbitals_assigned(j) ) then

             write(DECinfo%output,'(1X,a,i6,4X,i6,4X,g10.4,4X,g20.10)') '#PAIR#',j,i,&
                  & bohr_to_angstrom*distance_table(i,j), ccsd_matrix(i,j)

          end if

       end do
    end do


  end subroutine print_ccsd_full


  !> \brief: calculate E[5] contribution to ccsd(t) energy correction for full molecule calculation
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine ccsdpt_energy_e5_full(nocc,nvirt,natoms,offset,ccsd_singles,ccsdpt_singles,&
                             & occ_orbitals,unocc_orbitals,e5_matrix,ccsdpt_e5)

    implicit none

    !> ccsd and ccsd(t) singles amplitudes
    type(array2), intent(inout) :: ccsd_singles, ccsdpt_singles
    !> dimensions
    integer, intent(in) :: nocc, nvirt, natoms, offset
    !> occupied orbital information
    type(ccorbital), dimension(nocc+offset), intent(inout) :: occ_orbitals
    !> virtual orbital information
    type(ccorbital), dimension(nvirt), intent(inout) :: unocc_orbitals
    !> etot
    real(realk), intent(inout) :: ccsdpt_e5
    real(realk), dimension(natoms,natoms), intent(inout) :: e5_matrix
    !> integers
    integer :: i,a,AtomI,AtomA
    !> tmp energy real
    real(realk) :: energy_tmp

    ! ***********************
    !   do E[5] energy part
    ! ***********************

    ccsdpt_e5 = 0.0E0_realk

    !$OMP PARALLEL DO DEFAULT(NONE),PRIVATE(i,a,energy_tmp,AtomI,AtomA),&
    !$OMP& SHARED(ccsd_singles,ccsdpt_singles,nocc,nvirt,offset,occ_orbitals,unocc_orbitals),&
    !$OMP& REDUCTION(+:ccsdpt_e5),REDUCTION(+:e5_matrix)
    do i=1,nocc
    AtomI = occ_orbitals(i+offset)%CentralAtom
       do a=1,nvirt
       AtomA = unocc_orbitals(a)%CentralAtom

           energy_tmp = ccsd_singles%val(a,i) * ccsdpt_singles%val(a,i)
           e5_matrix(AtomA,AtomI) = e5_matrix(AtomA,AtomI) + energy_tmp
           ccsdpt_e5 = ccsdpt_e5 + energy_tmp

       end do
    end do
    !$OMP END PARALLEL DO

    ! get total fifth-order energy correction
    e5_matrix = 2.0E0_realk * e5_matrix
    ccsdpt_e5 = 2.0E0_realk * ccsdpt_e5

    ! ******************************
    !   done with E[5] energy part
    ! ******************************

  end subroutine ccsdpt_energy_e5_full

  !> \brief: print out fifth-order pair interaction energies for full molecule calculation 
  !> \author: Janus Juul Eriksen
  !> \date: February 2013
  subroutine print_e5_full(natoms,e5_matrix,orbitals_assigned,distance_table)

    implicit none

    !> number of atoms in molecule
    integer, intent(in) :: natoms
    !> matrices containing E[4] energies and interatomic distances
    real(realk), dimension(natoms,natoms), intent(inout) :: e5_matrix, distance_table
    !> vector handling how the orbitals are assigned?
    logical, dimension(natoms), intent(inout) :: orbitals_assigned
    !> loop counters
    integer :: i,a
    real(realk), parameter :: bohr_to_angstrom = 0.5291772083E0_realk

    ! print out fragment energies

    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,'(1X,a)') '*                         E[5] energies                       *'
    write(DECinfo%output,'(1X,a)') '***************************************************************'
    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,'(8X,a)') '-- Pair fragment energies (fifth--order E[5])          '
    write(DECinfo%output,'(9X,a)') '-------    ------    ----------    --------------------'
    write(DECinfo%output,'(9X,a)') 'P(virt)    Q(occ)      R(Ang)           E(PQ)          '
    write(DECinfo%output,'(9X,a)') '-------    ------    ----------    --------------------'
    write(DECinfo%output,*)

    ! the total singles energy must result from an unrestricted summation over all occ and virt indices
    ! as we are only interested in general orbital interactions and hence not the nature (occ/virt)
    ! of the individual orbitals

    do i=1,natoms
       do a=1,natoms

          ! write increments only if pair interaction energy is nonzero
          if( orbitals_assigned(i) .and. orbitals_assigned(a) ) then

             if (i .eq. a) then
                write(DECinfo%output,'(1X,a,i7,4X,i6,4X,g10.4,4X,g20.10)') '#PAIR#',a,i,&
                     &0.000, e5_matrix(a,i)

             else

                write(DECinfo%output,'(1X,a,i7,4X,i6,4X,g10.4,4X,g20.10)') '#PAIR#',a,i,&
                     &bohr_to_angstrom*distance_table(a,i), e5_matrix(a,i)

             end if

          end if

       end do
    end do

  end subroutine print_e5_full


  !> \brief Get MO integrals for CCSD(T) (in canonical basis), see integral storing order below.
  !> \author Janus Eriksen and Kasper Kristensen
  !> \date September-October 2012
  subroutine get_CCSDpT_integrals(MyLsitem,nbasis,nocc,nvirt,Cocc,Cvirt,JAIK,ABIJ,CBAI)

    implicit none

    !> Integral info
    type(lsitem), intent(inout) :: mylsitem
    !> Number of basis functions
    integer,intent(in) :: nbasis
    !> Number of occupied orbitals
    integer,intent(in) :: nocc
    !> Number of virtual orbitals
    integer,intent(in) :: nvirt
    !> Occupied MO coefficients
    real(realk), dimension(nbasis,nocc),intent(in) :: Cocc
    !> Virtual MO coefficients
    real(realk), dimension(nbasis,nvirt),intent(in) :: Cvirt
    ! JIAK: Integrals (AI|JK) in the order (J,A,I,K)
    type(array4), intent(inout) :: JAIK
    ! ABIJ: Integrals (AI|BJ) in the order (A,B,I,J)
    type(array4), intent(inout) :: ABIJ
    ! CBAI: Integrals (AI|BC) in the order (C,B,A,I)
    type(array), intent(inout) :: CBAI
    integer :: gammadim, alphadim,iorb
    integer :: alphaB,gammaB,dimAlpha,dimGamma,idx
    real(realk),pointer :: tmp1(:),tmp2(:),tmp3(:)
    integer(kind=long) :: size1,size2,size3
    integer :: GammaStart, GammaEnd, AlphaStart, AlphaEnd,m,k,n,i,dims(4),order(4)
    logical :: FullRHS,doscreen
    real(realk) :: tcpu, twall
    real(realk),pointer :: CoccT(:,:), CvirtT(:,:)
    type(array4) :: JAIB
    integer :: MaxActualDimAlpha,nbatchesAlpha,nbatches
    integer :: MaxActualDimGamma,nbatchesGamma
    type(batchtoorb), pointer :: batch2orbAlpha(:)
    type(batchtoorb), pointer :: batch2orbGamma(:)
    integer, pointer :: orb2batchAlpha(:), batchdimAlpha(:), batchsizeAlpha(:), batchindexAlpha(:)
    integer, pointer :: orb2batchGamma(:), batchdimGamma(:), batchsizeGamma(:), batchindexGamma(:)
    TYPE(DECscreenITEM)   :: DecScreen
    ! distribution stuff needed for mpi parallelization
    integer, pointer :: distribution(:)
    Character            :: intSpec(5)
    integer :: myload

    ! Lots of timings
    call LSTIMER('START',tcpu,twall,DECinfo%output)

    ! Integral screening?
    doscreen = mylsitem%setting%scheme%cs_screen.OR.&
         & mylsitem%setting%scheme%ps_screen

    ! allocate arrays to update during integral loop 
    ! **********************************************
    
    ! note 1: this must be done before call to get_optimal_batch_sizes_ccsdpt_integrals
    ! note 2: these integrals will be reordered into the output structures

    ! JAIK: Integrals (AI|KJ) in the order (J,A,I,K)
    dims = [nocc,nvirt,nocc,nocc]
    JAIK = array4_init_standard(dims)

    ! JAIB: Integrals (AI|BJ) in the order (J,A,I,B)
    dims = [nocc,nvirt,nocc,nvirt]
    JAIB = array4_init_standard(dims)

    ! CBAI: Integrals (AB|IC) in the order (C,B,A,I)
    dims = [nvirt,nvirt,nvirt,nocc]

#ifdef VAR_LSMPI

    CBAI = array_init(dims,4,TILED_DIST,ALL_INIT,[nvirt,nvirt,nvirt,1])
    call array_zero_tiled_dist(CBAI)

#else

    CBAI = array_init(dims,4)

#endif

    ! For efficiency when calling dgemm, save transposed matrices
    call mem_alloc(CoccT,nocc,nbasis)
    call mem_alloc(CvirtT,nvirt,nbasis)
    call mat_transpose(Cocc,nbasis,nocc,CoccT)
    call mat_transpose(Cvirt,nbasis,nvirt,CvirtT)

    ! Determine optimal batchsizes and corresponding sizes of arrays
    call get_optimal_batch_sizes_ccsdpt_integrals(mylsitem,nbasis,nocc,nvirt,alphadim,gammadim,&
         & size1,size2,size3)


    ! ************************************************
    ! * Determine batch information for Gamma batch  *
    ! ************************************************

    ! Orbital to batch information
    ! ----------------------------
    call mem_alloc(orb2batchGamma,nbasis)
    call build_batchesofAOS(DECinfo%output,mylsitem%setting,gammadim,&
         & nbasis,MaxActualDimGamma,batchsizeGamma,batchdimGamma,batchindexGamma,&
         & nbatchesGamma,orb2BatchGamma)

    write(DECinfo%output,*) 'BATCH: Number of Gamma batches   = ', nbatchesGamma

    ! Translate batchindex to orbital index
    ! -------------------------------------
    call mem_alloc(batch2orbGamma,nbatchesGamma)

    do idx=1,nbatchesGamma

       call mem_alloc(batch2orbGamma(idx)%orbindex,batchdimGamma(idx) )
       batch2orbGamma(idx)%orbindex = 0
       batch2orbGamma(idx)%norbindex = 0

    end do

    do iorb=1,nbasis

       idx = orb2batchGamma(iorb)
       batch2orbGamma(idx)%norbindex = batch2orbGamma(idx)%norbindex+1
       K = batch2orbGamma(idx)%norbindex
       batch2orbGamma(idx)%orbindex(K) = iorb

    end do

    ! ************************************************
    ! * Determine batch information for Alpha batch  *
    ! ************************************************

    ! Orbital to batch information
    ! ----------------------------
    call mem_alloc(orb2batchAlpha,nbasis)
    call build_batchesofAOS(DECinfo%output,mylsitem%setting,alphadim,&
         & nbasis,MaxActualDimAlpha,batchsizeAlpha,batchdimAlpha,batchindexAlpha,&
         & nbatchesAlpha,orb2BatchAlpha)

    write(DECinfo%output,*) 'BATCH: Number of Alpha batches   = ', nbatchesAlpha

    ! Translate batchindex to orbital index
    ! -------------------------------------
    call mem_alloc(batch2orbAlpha,nbatchesAlpha)

    do idx=1,nbatchesAlpha

       call mem_alloc(batch2orbAlpha(idx)%orbindex,batchdimAlpha(idx) )
       batch2orbAlpha(idx)%orbindex = 0
       batch2orbAlpha(idx)%norbindex = 0

    end do

    do iorb=1,nbasis

       idx = orb2batchAlpha(iorb)
       batch2orbAlpha(idx)%norbindex = batch2orbAlpha(idx)%norbindex+1
       K = batch2orbAlpha(idx)%norbindex
       batch2orbAlpha(idx)%orbindex(K) = iorb

    end do

    ! Set integral info
    ! *****************
    INTSPEC(1)='R' !R = Regular Basis set on the 1th center 
    INTSPEC(2)='R' !R = Regular Basis set on the 2th center 
    INTSPEC(3)='R' !R = Regular Basis set on the 3th center 
    INTSPEC(4)='R' !R = Regular Basis set on the 4th center 
    INTSPEC(5)='C' !C = Coulomb operator
    call II_precalc_DECScreenMat(DecScreen,DECinfo%output,6,mylsitem%setting,&
            & nbatches,nbatchesAlpha,nbatchesGamma,INTSPEC)

    if (doscreen) then

       call II_getBatchOrbitalScreen(DecScreen,mylsitem%setting,&
            & nbasis,nbatchesAlpha,nbatchesGamma,&
            & batchsizeAlpha,batchsizeGamma,batchindexAlpha,batchindexGamma,&
            & batchdimAlpha,batchdimGamma,DECinfo%output,DECinfo%output)

    end if

    FullRHS = (nbatchesGamma .eq. 1) .and. (nbatchesAlpha .eq. 1)


    ! Allocate array for AO integrals
    ! *******************************
    call mem_alloc(tmp1,size1)
    call mem_alloc(tmp2,size2)
    call mem_alloc(tmp3,size3)

#ifdef VAR_LSMPI

    ! alloc distribution array
    nullify(distribution)
    call mem_alloc(distribution,nbatchesGamma*nbatchesAlpha)

    ! init distribution
    distribution = 0
    myload = 0
    call distribute_mpi_jobs(distribution,nbatchesAlpha,nbatchesGamma,batchdimAlpha,batchdimGamma,myload)

#endif

    ! Start looping over gamma and alpha batches and calculate integrals
    ! ******************************************************************

    BatchGamma: do gammaB = 1,nbatchesGamma  ! AO batches
       dimGamma = batchdimGamma(gammaB)                           ! Dimension of gamma batch
       GammaStart = batch2orbGamma(gammaB)%orbindex(1)            ! First index in gamma batch
       GammaEnd = batch2orbGamma(gammaB)%orbindex(dimGamma)       ! Last index in gamma batch


       BatchAlpha: do alphaB = 1,nbatchesAlpha  ! AO batches
          dimAlpha = batchdimAlpha(alphaB)                                ! Dimension of alpha batch
          AlphaStart = batch2orbAlpha(alphaB)%orbindex(1)                 ! First index in alpha batch
          AlphaEnd = batch2orbAlpha(alphaB)%orbindex(dimAlpha)            ! Last index in alpha batch

#ifdef VAR_LSMPI

          ! distribute tasks
          if (distribution((alphaB-1)*nbatchesGamma+gammaB) .ne. infpar%lg_mynum) then

             cycle BatchAlpha

          end if

          write (DECinfo%output, '("Rank(T) ",I3," starting job (",I3,"/",I3,",",I3,"/",I3,")")'),infpar%lg_mynum,alphaB,&
                          &nbatchesAlpha,gammaB,nbatchesGamma

#endif

          if (doscreen) mylsitem%setting%LST_GAB_RHS => DECSCREEN%masterGabRHS
          if (doscreen) mylsitem%setting%LST_GAB_LHS => DECSCREEN%batchGab(alphaB,gammaB)%p


          ! Get (beta delta | alphaB gammaB) integrals using (beta,delta,alphaB,gammaB) ordering
          ! ************************************************************************************
          call II_GET_DECPACKED4CENTER_J_ERI(DECinfo%output,DECinfo%output, &
               & mylsitem%setting,tmp1,batchindexAlpha(alphaB),batchindexGamma(gammaB),&
               & batchsizeAlpha(alphaB),batchsizeGamma(gammaB),nbasis,nbasis,dimAlpha,dimGamma,&
               & FullRHS,nbatches,INTSPEC)

          ! tmp2(delta,alphaB,gammaB;A) = sum_{beta} [tmp1(beta;delta,alphaB,gammaB)]^T [Cvirt(beta,A)}^T
          m = nbasis*dimGamma*dimAlpha
          k = nbasis
          n = nvirt
          call dec_simple_dgemm(m,k,n,tmp1,CvirtT,tmp2,'T','T')

          ! tmp3(B;alphaB,gammaB,A) = sum_{delta} CvirtT(B,delta) tmp2(delta;alphaB,gammaB,A)
          m = nvirt
          k = nbasis
          n = dimAlpha*dimGamma*nvirt
          call dec_simple_dgemm(m,k,n,CvirtT,tmp2,tmp3,'N','N')

          ! tmp1(I;,alphaB,gammaB,A) = sum_{delta} [Cocc(delta,I)]^T tmp2(delta,alphaB,gammaB,A)
          m = nocc
          k = nbasis
          n = dimAlpha*dimGamma*nvirt
          call dec_simple_dgemm(m,k,n,CoccT,tmp2,tmp1,'N','N')

          ! Reorder: tmp1(I,alphaB;gammaB,A) --> tmp2(gammaB,A;I,alphaB)
          m = nocc*dimAlpha
          n = dimGamma*nvirt
          call mat_transpose(tmp1,m,n,tmp2)

          ! tmp1(J;A,I,alphaB) = sum_{gamma in gammaB} CoccT(J,gamma) tmp2(gamma,A,I,alphaB)
          m = nocc
          k = dimGamma
          n = nvirt*nocc*dimAlpha
          call dec_simple_dgemm(m,k,n,CoccT(1:nocc,GammaStart:GammaEnd),tmp2,tmp1,'N','N')

          ! JAIK(J,A,I;K) += sum_{alpha in alphaB} tmp1(J,A,I,alpha) [CoccT(K,alpha)]^T
          m = nvirt*nocc**2
          k = dimAlpha
          n = nocc
          call dec_simple_dgemm_update(m,k,n,tmp1,&
                                     & CoccT(1:nocc,AlphaStart:AlphaEnd),JAIK%val,'N','T')

          ! JAIB(J,A,I;B) += sum_{alpha in alphaB} tmp1(J,A,I,alpha) [CvirtT(B,alpha)]^T
          m = nvirt*nocc**2
          k = dimAlpha
          n = nvirt
          call dec_simple_dgemm_update(m,k,n,tmp1,&
                                     & CvirtT(1:nvirt,AlphaStart:AlphaEnd),JAIB%val,'N','T')

          ! Reorder: tmp3(B,alphaB;gammaB,A) --> tmp1(gammaB,A;B,alphaB)
          m = nvirt*dimAlpha
          n = dimGamma*nvirt
          call mat_transpose(tmp3,m,n,tmp1)

          ! tmp3(C;A,B,alphaB) = sum_{gamma in gammaB} CvirtT(C,gamma) tmp1(gamma,A,B,alphaB)
          m = nvirt
          k = dimGamma
          n = dimAlpha*nvirt**2
          call dec_simple_dgemm(m,k,n,CvirtT(1:nvirt,GammaStart:GammaEnd),tmp1,tmp3,'N','N')

          ! reorder tmp1 and do CBAI(B,A,C,I) += sum_{i in IB} tmp1(B,A,C,i)
          m = nvirt**3
          k = dimAlpha
          n = 1

#ifdef VAR_LSMPI

          do i=1,nocc

             ! tmp1(C,A,B,i) = sum_{alpha in alphaB} tmp3(C,A,B,alpha) [CoccT(i,alpha)]^T
             call dec_simple_dgemm(m,k,n,tmp3,CoccT(i,AlphaStart:AlphaEnd),tmp1,'N','T')

             ! *** tmp1 corresponds to (AB|iC) in Mulliken notation. Noting that the v³o integrals
             ! are normally written as g_{AIBC}, we may also write this Mulliken integral (with substitution
             ! of dummy indices A=B, B=C, and C=A) as (BC|IA). In order to align with the CBAI order of
             ! ccsd(t) driver routine, we reorder as:
             ! (BC|IA) --> (CB|AI), i.e., tmp1(C,A,B,i) = ABCI(A,B,C,i) (norm. notat.) --> 
             !                                            tmp1(C,B,A,i) (norm. notat.) = tmp1(B,A,C,i) (notat. herein)
             ! 
             ! next, we accumulate
             ! CBAI(B,A,C,I) += sum_{i in IB} tmp1(B,A,C,i)

             call array_reorder_3d(1.0E0_realk,tmp1,nvirt,nvirt,nvirt,[3,2,1],0.0E0_realk,tmp2)

             call array_accumulate_tile(CBAI,i,tmp2,nvirt**3)

          end do

#else

          do i=1,nocc

             ! for description, see mpi section above
             call dec_simple_dgemm(m,k,n,tmp3,CoccT(i,AlphaStart:AlphaEnd),tmp1,'N','T')

             call array_reorder_3d(1.0E0_realk,tmp1,nvirt,nvirt,nvirt,[3,2,1],1.0E0_realk,CBAI%elm4(:,:,:,i))

          end do

#endif

       end do BatchAlpha
    end do BatchGamma

#ifdef VAR_LSMPI

    if (infpar%lg_nodtot .gt. 1) then

       ! now, reduce o^2v^2 and o^3v integrals onto master
       call lsmpi_local_allreduce(JAIB%val,nocc,nvirt,nocc,nvirt)
       call lsmpi_local_allreduce(JAIK%val,nocc,nvirt,nocc,nocc) 

    end if

    ! dealloc distribution array
    call mem_dealloc(distribution)

#endif

    ! free stuff
    ! **********
    call mem_dealloc(tmp1)
    call mem_dealloc(tmp2)
    call mem_dealloc(tmp3)
    call free_decscreen(DECSCREEN)
    call mem_dealloc(CoccT)
    call mem_dealloc(CvirtT)
    call mem_dealloc(orb2batchGamma)
    call mem_dealloc(batchdimGamma)
    call mem_dealloc(batchsizeGamma)
    call mem_dealloc(batchindexGamma)
    do idx=1,nbatchesGamma
       call mem_dealloc(batch2orbGamma(idx)%orbindex)
    end do
    call mem_dealloc(batch2orbGamma)
    call mem_dealloc(orb2batchAlpha)
    call mem_dealloc(batchdimAlpha)
    call mem_dealloc(batchsizeAlpha)
    call mem_dealloc(batchindexAlpha)
    do idx=1,nbatchesAlpha
       call mem_dealloc(batch2orbAlpha(idx)%orbindex)
       batch2orbAlpha(idx)%orbindex => null()
    end do
    call mem_dealloc(batch2orbAlpha)
    nullify(mylsitem%setting%LST_GAB_LHS)
    nullify(mylsitem%setting%LST_GAB_RHS)

    ! finally, reorder JAIB to final output
    ! *********************************************

    ! ** JAIB corresponds to (AI|BJ) in Mulliken notation. Noting that the v²o² integrals
    ! are normally written as g_{AIBJ} = g_{BJAI}, we may also write this Mulliken integral (with substitution
    ! of dummy indices A=B and B=A) as (BI|AJ). In order to align with the ABIJ order of
    ! ccsd(t) driver routine, we reorder as:
    ! (BI|AJ) --> (AB|IJ), i.e., JAIB(J,A,I,B) = JBIA(J,B,I,A) (norm. notat.) --> 
    !                                            BAIJ(B,A,I,J) (norm. notat.) =
    !                                            ABIJ(A,B,I,J) (notat. herein)

    order = [2,4,3,1]
    dims = [nvirt,nvirt,nocc,nocc]
    ABIJ = array4_init_standard(dims)
    
    call array_reorder_4d(1.0E0_realk,JAIB%val,JAIB%dims(1),JAIB%dims(2),&
         & JAIB%dims(3),JAIB%dims(4),order,0.0E0_realk,ABIJ%val)
    
    call array4_free(JAIB)

    call LSTIMER('CCSD(T) INT',tcpu,twall,DECinfo%output)

  end subroutine get_CCSDpT_integrals

  !> \brief Get optimal batch sizes to be used in get_CCSDpT_integrals
  !> using the available memory.
  !> \author Kasper Kristensen & Janus Eriksen
  !> \date September 2011, rev. October 2012
  subroutine get_optimal_batch_sizes_ccsdpt_integrals(mylsitem,nbasis,nocc,nvirt,alphadim,gammadim,&
     & size1,size2,size3)

    implicit none
  
    !> Integral info
    type(lsitem), intent(inout) :: mylsitem
    !> Number of AO basis functions
    integer,intent(in) :: nbasis
    !> Number of occupied (AOS) orbitals
    integer,intent(in) :: nocc
    !> Number of virt (AOS) orbitals
    integer,intent(in) :: nvirt
    !> Max size for AO alpha batch
    integer,intent(inout) :: alphadim
    !> Max size for AO gamma batch
    integer,intent(inout) :: gammadim
    !> Dimension of temporary array 1
    integer(kind=long),intent(inout) :: size1
    !> Dimension of temporary array 2
    integer(kind=long),intent(inout) :: size2
    !> Dimension of temporary array 3
    integer(kind=long),intent(inout) :: size3
    !> memory reals
    real(realk) :: MemoryNeeded, MemoryAvailable
    integer :: MaxAObatch, MinAOBatch, AlphaOpt, GammaOpt,alpha,gamma


    ! Memory currently available
    ! **************************
    call get_currently_available_memory(MemoryAvailable)
    ! Note: We multiply by 85 % to be on the safe side!
    MemoryAvailable = 0.85*MemoryAvailable
  
  
  
    ! Maximum and minimum possible batch sizes
    ! ****************************************
  
    ! The largest possible AO batch is the number of basis functions
    MaxAObatch = nbasis
  
    ! The smallest possible AO batch depends on the basis set
    ! (More precisely, if all batches are made as small as possible, then the
    !  call below determines the largest of these small batches).
    call determine_maxBatchOrbitalsize(DECinfo%output,mylsitem%setting,MinAObatch)
  
  
    ! Initialize batch sizes to be the minimum possible and then start increasing sizes below
    AlphaDim=MinAObatch
    GammaDim=MinAObatch
  
  
    ! Gamma batch size
    ! =================================
    GammaLoop: do gamma = MaxAObatch,MinAOBatch,-1
  
       call get_max_arraysizes_for_ccsdpt_integrals(alphaDim,gamma,nbasis,nocc,nvirt,&
            & size1,size2,size3,MemoryNeeded)
  
       if(MemoryNeeded < MemoryAvailable .or. (gamma==minAObatch) ) then
          GammaOpt = gamma
          exit
       end if
  
    end do GammaLoop
  
    ! If gamma batch size was set manually we use that value instead
    if(DECinfo%ccsdGbatch/=0) then
       write(DECinfo%output,*) 'Gamma batch size was set manually, use that value instead!'
       GammaOpt=DECinfo%ccsdGbatch
    end if
  
    ! The optimal gamma batch size is GammaOpt.
    ! We now find the maximum possible gamma batch size smaller than or equal to GammaOpt
    ! and store this number in gammadim.
    call determine_MaxOrbitals(DECinfo%output,mylsitem%setting,GammaOpt,gammadim)
  
  
    ! Largest possible alpha batch size
    ! =================================
    AlphaLoop: do alpha = MaxAObatch,MinAOBatch,-1
  
       call get_max_arraysizes_for_ccsdpt_integrals(alpha,gammadim,nbasis,nocc,nvirt,&
            & size1,size2,size3,MemoryNeeded)
  
       if(MemoryNeeded < MemoryAvailable .or. (alpha==minAObatch) ) then
          AlphaOpt = alpha
          exit
       end if
  
    end do AlphaLoop
  
    ! If alpha batch size was set manually we use that value instead
    if(DECinfo%ccsdAbatch/=0) then
       write(DECinfo%output,*) 'Alpha batch size was set manually, use that value instead!'
       AlphaOpt=DECinfo%ccsdAbatch
    end if
  
    ! The optimal alpha batch size is AlphaOpt.
    ! We now find the maximum possible alpha batch size smaller than or equal to AlphaOpt
    ! and store this number in alphadim.
    call determine_MaxOrbitals(DECinfo%output,mylsitem%setting,AlphaOpt,alphadim)
  
  
    ! Print out and sanity check
    ! ==========================
  
    write(DECinfo%output,*)
    write(DECinfo%output,*)
    write(DECinfo%output,*) '======================================================================='
    write(DECinfo%output,*) '                     CCSD(T) INTEGRALS: MEMORY SUMMARY                 '
    write(DECinfo%output,*) '======================================================================='
    write(DECinfo%output,*)
    write(DECinfo%output,*) 'To be on the safe side we use only 85% of the estimated available memory'
    write(DECinfo%output,*)
    write(DECinfo%output,'(1X,a,g10.3)') '85% of available memory (GB)            =', MemoryAvailable
    write(DECinfo%output,*)
    write(DECinfo%output,'(1X,a,i8)')    'Number of atomic basis functions        =', nbasis
    write(DECinfo%output,'(1X,a,i8)')    'Number of occupied orbitals             =', nocc
    write(DECinfo%output,'(1X,a,i8)')    'Number of virtual  orbitals             =', nvirt
    write(DECinfo%output,'(1X,a,i8)')    'Maximum alpha batch dimension           =', alphadim
    write(DECinfo%output,'(1X,a,i8)')    'Maximum gamma batch dimension           =', gammadim
    write(DECinfo%output,'(1X,a,g14.3)') 'Size of tmp array 1                     =', size1*realk*1.0E-9
    write(DECinfo%output,'(1X,a,g14.3)') 'Size of tmp array 2                     =', size2*realk*1.0E-9
    write(DECinfo%output,'(1X,a,g14.3)') 'Size of tmp array 3                     =', size3*realk*1.0E-9
    write(DECinfo%output,*)
  
    ! Sanity check
    call get_max_arraysizes_for_ccsdpt_integrals(alphadim,gammadim,nbasis,nocc,nvirt,&
         & size1,size2,size3,MemoryNeeded)  
    if(MemoryNeeded > MemoryAvailable) then
       write(DECinfo%output,*) 'Requested/available memory: ', MemoryNeeded, MemoryAvailable
       call lsquit('CCSD(T) integrals: Insufficient memory!',-1)
    end if


  end subroutine get_optimal_batch_sizes_ccsdpt_integrals



  !> \brief Get sizes of temporary arrays used in CCSD(T) integral routine (get_CCSDpT_integrals)
  !> with the chosen AO batch sizes.
  !> NOTE: If get_CCSDpT_integrals is modified, this routine must be changed accordingly!
  !> \author Kasper Kristensen & Janus Eriksen
  !> \date September 2011, rev. October 2012
  subroutine get_max_arraysizes_for_ccsdpt_integrals(alphadim,gammadim,nbasis,nocc,nvirt,&
                     & size1,size2,size3,mem)
    implicit none
    !> Max size for AO alpha batch
    integer,intent(in) :: alphadim
    !> Max size for AO gamma batch
    integer,intent(in) :: gammadim
    !> Number of AO basis functions
    integer,intent(in) :: nbasis
    !> Number of occupied (AOS) orbitals
    integer,intent(in) :: nocc
    !> Number of virt (AOS) orbitals
    integer,intent(in) :: nvirt
    !> Dimension of temporary array 1
    integer(kind=long),intent(inout) :: size1
    !> Dimension of temporary array 2
    integer(kind=long),intent(inout) :: size2
    !> Dimension of temporary array 3
    integer(kind=long),intent(inout) :: size3
    !> Tot size of temporary arrays (in GB)
    real(realk), intent(inout) :: mem
    real(realk) :: GB
  
    GB = 1.000E-9_realk ! 1 GB
    ! Array sizes needed in get_CCSDpT_integrals are checked and the largest one is found
  
    ! Tmp array 1 (five candidates)
    size1 = i8*alphadim*gammadim*nbasis*nbasis
    size1 = max(size1,i8*nvirt**2*gammadim*alphadim)
    size1 = max(size1,i8*nvirt*nocc*gammadim*alphadim)
    size1 = max(size1,i8*nvirt*nocc**2*alphadim)
    size1 = max(size1,i8*nvirt**3)
  
    ! tmp array 2 (two candidates)
    size2 = i8*alphadim*gammadim*nbasis*nvirt
    size2 = max(size2,size1)
  
    ! Tmp array3 (two candidates)
    size3 = i8*alphadim*gammadim*nvirt**2
    size3 = max(size3,i8*alphadim*nvirt**3)
  
    ! Size = size1+size2+size3,  convert to GB
    mem = realk*GB*(size1+size2+size3)


  end subroutine get_max_arraysizes_for_ccsdpt_integrals

end module ccsdpt_module

  !> \brief slaves enter here from lsmpi_slave (or dec_lsmpi_slave) and need to get to work 
  !> \author Janus Juul Eriksen
  !> \date x-mas 2012
#ifdef VAR_LSMPI

  subroutine ccsdpt_slave()

  use infpar_module
  use lsmpi_type
  use decmpi_module

  use precision
  use dec_typedef_module
  use memory_handling
  use lstiming, only: lstimer
  use typedeftype, only: Lsitem,lssetting

  ! DEC DEPENDENCIES (within deccc directory)  
  ! *****************************************
  use array2_simple_operations, only: array2_init_plain,array2_free 
  use array4_simple_operations, only: array4_init_standard,array4_free
  use atomic_fragment_operations
  use ccsdpt_module, only: ccsdpt_driver

    implicit none
    integer :: nocc, nvirt,nbasis
    real(realk), pointer :: ppfock(:,:), qqfock(:,:), ypo(:,:), ypv(:,:)
    type(array2) :: ccsdpt_t1
    type(array4) :: ccsd_t2, ccsdpt_t2
    type(lsitem) :: mylsitem

    ! call ccsd(t) data routine in order to receive data from master
    call mpi_communicate_ccsdpt_calcdata(nocc,nvirt,nbasis,ppfock,qqfock,ypo,ypv,ccsd_t2%val,mylsitem)

    ! init and receive ppfock
    call mem_alloc(ppfock,nocc,nocc)
    call ls_mpibcast(ppfock,nocc,nocc,infpar%master,infpar%lg_comm)

    ! init and receive qqfock
    call mem_alloc(qqfock,nvirt,nvirt)
    call ls_mpibcast(qqfock,nvirt,nvirt,infpar%master,infpar%lg_comm)

    ! init and receive ypo
    call mem_alloc(ypo,nbasis,nocc)
    call ls_mpibcast(ypo,nbasis,nocc,infpar%master,infpar%lg_comm)

    ! init and receive ypv
    call mem_alloc(ypv,nbasis,nvirt)
    call ls_mpibcast(ypv,nbasis,nvirt,infpar%master,infpar%lg_comm)

    ! init and receive ccsd_doubles array4 structure
    ccsd_t2 = array4_init([nvirt,nocc,nvirt,nocc])
    call ls_mpibcast(ccsd_t2%val,nvirt,nocc,nvirt,nocc,infpar%master,infpar%lg_comm)

    ! init ccsd(t) singles and ccsd(t) doubles
    ccsdpt_t1 = array2_init_plain([nvirt,nocc])
    ccsdpt_t2 = array4_init_standard([nvirt,nvirt,nocc,nocc])

    ! now enter the ccsd(t) driver routine
    call ccsdpt_driver(nocc,nvirt,nbasis,ppfock,qqfock,ypo,ypv,mylsitem,ccsd_t2,&
                         & ccsdpt_t1,ccsdpt_t2)

    ! now, release all amplitude arrays, both ccsd and ccsd(t)
    call array2_free(ccsdpt_t1)
    call array4_free(ccsd_t2)
    call array4_free(ccsdpt_t2)

    ! finally, release fragment or full molecule quantities
    call ls_free(mylsitem)
    call mem_dealloc(ppfock)
    call mem_dealloc(qqfock)
    call mem_dealloc(ypo)
    call mem_dealloc(ypv)

  end subroutine ccsdpt_slave

#endif