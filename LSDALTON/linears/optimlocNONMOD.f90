!##########################################################
!#            GENERAL INTERFACE ROUTINES                  #
!# Below are routine that are kept outside modules.       #
!# They are interface routines to solvers (precond/       #
!# linear trans.) and lsdalton main program (optimloc).   #
!#                                                        #
!##########################################################


subroutine LocalityMeasure(CFG,ls,cmo,ncore,nval,nvirt)
use TYPEDEF,only: count_ncore
use precision
use Pipek
use orbspread_module
use charge_module
use davidson_settings
use matrix_util
use loc_utils
use typedeftype
use matrix_module, only: matrix
use matrix_operations 
use matrix_util, only: matrix_exponential
!use matrix_module
!use matrix_operations
!use matrix_operations_aux
use memory_handling
implicit none
type(RedSpaceItem) :: CFG
type(orbspread_data)  :: orbspread_input
type(lsitem) :: ls
type(matrix) :: cmo,CMOblock
integer :: i,ncore,nval,nvirt,nbas 
real(realk), pointer :: kurtvec(:),tmp(:)

nbas = cmo%nrow

  ! *** COMPUTE FOURTH MOMENT FOR ORBITALS ***
  CFG%KURT%crossterms=.true.
  CFG%KURT%m=1
  call kurt_initAO(CFG%KURT,ls,cmo%nrow)
  call orbspread_propint(orbspread_input,ls)
if (ncore > 0) then
!######### CORE #############
  CFG%KURT%norb=ncore
  !get core block
  call mat_init(CMOblock,nbas,ncore)
  call mem_alloc(tmp,nbas*ncore)
  call mat_retrieve_block(CMO,tmp,nbas,ncore,1,1)
  call mat_set_from_full(tmp,1d0,CMOblock)
  call mem_dealloc(tmp)
  call kurt_initMO(CFG%KURT,CMOblock)
  call orbspread_init(orbspread_input,1,ncore)
  call orbspread_update(orbspread_input,CMOblock)
  write(ls%lupri,'(a)') '**** CORE LOCALITY  ****'
  do i=1,ncore
     write(ls%lupri, '(a,i5,f15.3,f15.3)') 'FINAL: orbspread, fourth orbspread :'&
     &, i,dsqrt(orbspread_input%spread2(i))
  end do
  write(CFG%lupri,*)
  write(CFG%lupri,'(a)') 'Maximum **************** CORE **********************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Maximum orbspread and orb.number    : ',&
  &dsqrt(maxval(orbspread_input%spread2))&
  &,maxloc(orbspread_input%spread2)
  call mem_alloc(kurtvec,ncore)
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Maximum fourth spread and orb.number : ',&
  &maxval(kurtvec),maxloc(kurtvec)
  write(CFG%lupri,'(a)') 'Maximum *********************************************'
  write(CFG%lupri,'(a)') 'Minimum *********************************************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Minimum orbspread and orb.number     : ',&
  &dsqrt(minval(orbspread_input%spread2))&
  &,minloc(orbspread_input%spread2)
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Minimum fourth spread and orb.number : ',&
  &minval(kurtvec),minloc(kurtvec)
  write(CFG%lupri,'(a)') 'Minimum ********************************************'
  call mem_dealloc(kurtvec)
  call kurt_freeMO(CFG%KURT)
  call orbspread_free(orbspread_input)
  call mat_free(CMOblock)
end if
!######### VALENCE #############
if (nval > 0) then
  CFG%KURT%norb = nval
  call mat_init(CMOblock,nbas,nval)
  call mem_alloc(tmp,nbas*nval)
  call mat_retrieve_block(CMO,tmp,nbas,nval,1,ncore+1)
  call mat_set_from_full(tmp,1d0,CMOblock)
  call mem_dealloc(tmp)
  call kurt_initMO(CFG%KURT,CMOblock)
  call orbspread_init(orbspread_input,1,nval)
  call orbspread_update(orbspread_input,CMOblock)
  write(CFG%lupri,'(a)') '**** VALENCE LOCALITY  ****'
  do i=1,nval
     write(CFG%lupri, '(a,i5,f15.3,f15.3)') 'FINAL: orbspread, fourth orbspread :'&
     &, i+ncore,dsqrt(orbspread_input%spread2(i)),&
     &dsqrt(dsqrt(CFG%KURT%omega(i)))
  end do
  write(CFG%lupri,*)
  write(CFG%lupri,'(a)') 'Maximum *************** VALENCE ********************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Maximum orbspread and orb.number    : ',&
  &dsqrt(maxval(orbspread_input%spread2))&
  &,maxloc(orbspread_input%spread2)+ncore
  call mem_alloc(kurtvec,nval)
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Maximum fourth spread and orb.number : ',&
  &maxval(kurtvec),maxloc(kurtvec)+ncore
  write(CFG%lupri,'(a)') 'Maximum *********************************************'
  write(CFG%lupri,'(a)') 'Minimum *********************************************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Minimum orbspread and orb.number     : ',&
  &dsqrt(minval(orbspread_input%spread2))&
  &,minloc(orbspread_input%spread2)+ncore
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Minimum fourth spread and orb.number : ',&
  &(minval(kurtvec)),minloc(kurtvec)+ncore
  write(CFG%lupri,'(a)') 'Minimum ********************************************'
  write(CFG%lupri,*)
  call mem_dealloc(kurtvec)
  call kurt_freeMO(CFG%KURT)
  call orbspread_free(orbspread_input)
  call  mat_free(CMOblock)
end if

!######### VIRTUAL #############
if (nvirt > 0) then
  CFG%KURT%norb = nvirt
  call mat_init(CMOblock,nbas,nvirt)
  call mem_alloc(tmp,nbas*nvirt)
  call mat_retrieve_block(CMO,tmp,nbas,nvirt,1,ncore+nval+1)
  call mat_set_from_full(tmp,1d0,CMOblock)
  call mem_dealloc(tmp)
  call kurt_initMO(CFG%KURT,CMOblock)
  call orbspread_init(orbspread_input,1,nvirt)
  call orbspread_update(orbspread_input,CMOblock)
  write(CFG%lupri,'(a)') '**** VIRTUAL LOCALITY  ****'
  do i=1,nvirt
     write(CFG%lupri, '(a,i5,f15.3,f15.3)') 'FINAL: orbspread, fourth orbspread :'&
     &, i+ncore+nval,dsqrt(orbspread_input%spread2(i)),&
     &dsqrt(dsqrt(CFG%KURT%omega(i)))
  end do
  write(CFG%lupri,*)
  write(CFG%lupri,'(a)') 'Maximum **************** VIRTUAL *******************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Maximum orbspread and orb.number     : ',&
  &dsqrt(maxval(orbspread_input%spread2))&
  &,maxloc(orbspread_input%spread2)+ncore+nval
  call mem_alloc(kurtvec,nvirt)
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Maximum fourth spread and orb.number : ',&
  &maxval(kurtvec),maxloc(kurtvec)+ncore+nval
  write(CFG%lupri,'(a)') 'Maximum *********************************************'
  write(CFG%lupri,'(a)') 'Minimum *********************************************'
  write(CFG%lupri,'(a,f7.3,i5)') 'Minimum orbspread and orb.number    : ',&
  &dsqrt(minval(orbspread_input%spread2))&
  &,minloc(orbspread_input%spread2)+ncore+nval
  kurtvec= dsqrt(dsqrt(CFG%KURT%omega))
  write(ls%lupri,'(a,f7.3,i5)') 'Minimum fourth spread and orb.number : ',&
  &minval(kurtvec),minloc(kurtvec)+ncore+nval
  write(CFG%lupri,'(a)') 'Minimum *********************************************'
  write(CFG%lupri,*)
  call mem_dealloc(kurtvec)
  call kurt_freeMO(CFG%KURT)
  call orbspread_free(orbspread_input)
  call  mat_free(CMOblock)
end if


  call orbspread_propint_free(orbspread_input)
  call kurt_freeAO(CFG%KURT)

end subroutine LocalityMeasure

subroutine optimloc(CMO,nocc,m,ls,CFG)
use precision
use Pipek
use orbspread_module
use charge_module
use davidson_settings
use matrix_module, only: matrix
use matrix_operations 
use matrix_util, only: matrix_exponential
!use matrix_module
!use matrix_operations
!use matrix_operations_aux
use matrix_util
use loc_utils
!use typedef
use typedeftype
use LSTIMING
implicit none
type(RedSpaceItem) :: CFG
type(Matrix), target:: CMO
TYPE(lsitem) , intent(inout) :: ls
integer,       intent(in)    :: nocc
integer,       intent(in)    :: m(2)
integer                      :: nvirt, nbas, ncore, nval
type(Matrix)                 :: CMOo, CMOv, CMOc
type(Matrix), pointer        :: CMOs
integer     , pointer        :: selected(:)
real(realk), pointer      :: tmp(:)
type(orbspread_data)         :: inp
integer :: m_core
type(matrix) :: SC,CSC,S



nvirt=CMO%ncol - nocc
nbas =CMO%nrow
ncore = count_ncore(ls)
nval = nocc - ncore
CFG%lupri = ls%lupri
!Compute OrbLoc%SU needed for localization
if (CFG%ChargeLoc) then
   call mat_init(CFG%OrbLoc%SU,nbas,nbas)
   call get_correct_S(CFG,ls,nbas)
   CFG%OrbLoc%CMO => CMO
end if 
CFG%lupri = ls%lupri

if (CFG%KURT%TESTCASE) then
   call kurtosis_test(ls,cmo,nbas,CMO%ncol)
   return
elseif (CFG%PRINT_INFO) then
    call LocalityMeasure(CFG,ls,cmo,ncore,nval,nvirt)
    return
end if

!!!!!!!!!!!!!!!!! general, propint
if (CFG%orbspread)  call orbspread_propint(inp,ls)
if (CFG%kurtosis)   call kurt_initAO(CFG%KURT,ls,cmo%ncol)

if (.not. m(1)==0) then
CFG%KURT%m=m(1)
 if (ncore.gt.0) then
!!!!!!!!!!!!!!!! core
  !init
  call mat_init(CMOc,nbas,ncore)
  !get core block
  call mem_alloc(tmp,nbas*ncore)
  call mat_retrieve_block(CMO,tmp,nbas,ncore,1,1)
  call mat_set_from_full(tmp,1d0,CMOc)
  call mem_dealloc(tmp)

  !run localization
  write(ls%lupri,*) 'Localizing core: ', nbas, CMOc%ncol
  if (CFG%orbspread.or.CFG%kurtosis) then
      m_core = 1
  else
      m_core = 2
  end if

 if (ncore < 6) then
     write(ls%lupri,*) 'Too few orbitals to localize' 
 else
     write(ls%lupri,'(a)') 'Pred= ******* CORE LOCALIZATION ******* '
     call localize_davidson(CMOc,m_core,inp,ls,CFG)
 end if
  write(ls%lupri,*) 'Done localizing core '
  !set occupied block in CMO
  call mem_alloc(tmp,nbas*ncore)
  call mat_to_full(CMOc,1d0,tmp)
  call mat_free(CMOc)
  call mat_create_block(CMO,tmp,nbas,ncore,1,1)
  call mem_dealloc(tmp)
 endif
!!!!!!!!!!!!!!!!!! valence
!init
call mat_init(CMOo,nbas,nval)
!
!!get core block
call mem_alloc(tmp,nbas*nval)
call mat_retrieve_block(CMO,tmp,nbas,nval,1,ncore+1)
call mat_set_from_full(tmp,1d0,CMOo)
call mem_dealloc(tmp)

!run localization
write(ls%lupri,*) 'Localizing valence: ', nbas, CMOo%ncol
if (nval < 6) then
     write(ls%lupri,*) 'Too few orbitals to localize' 
else
   write(ls%lupri,'(a)') 'Pred= ******* VALENCE LOCALIZATION ******* '
   call localize_davidson(CMOo,m(1),inp,ls,CFG)
   write(ls%lupri,*) 'Done localizing valence '
end if  

  !set occupied block in CMO
  call mem_alloc(tmp,nbas*nval)
  call mat_to_full(CMOo,1d0,tmp)
  call mat_free(CMOo)
  call mat_create_block(CMO,tmp,nbas,nval,1,ncore+1)
  call mem_dealloc(tmp)
endif
if (.not. m(2) == 0) then
CFG%KURT%m=m(2)
!!!!!!!!!!!!!!!!! virtual
  !init
  call mat_init(CMOv,nbas,nvirt)

  !get occupied block
  call mem_alloc(tmp,nbas*nvirt)
  call mat_retrieve_block(CMO,tmp,nbas,nvirt,1,nocc+1)
  call mat_set_from_full(tmp,1d0,CMOv)
  call mem_dealloc(tmp)


  !run localization
  write(ls%lupri,*) 'Localizing virtual: ', nvirt
  if (nvirt < 6) then 
     write(ls%lupri,*) 'Too few orbitals to localize'
  else
     write(ls%lupri,'(a)') 'Pred= ******* VIRTUAL LOCALIZATION ******* '
     call localize_davidson(CMOv,m(2),inp,ls,CFG)
  end if
     
  !set occupied block in CMO
  call mem_alloc(tmp,nbas*nvirt)
  call mat_to_full(CMOv,1d0,tmp)
  call mat_free(CMOv)
  call mat_create_block(CMO,tmp,nbas,nvirt,1,nocc+1)
  call mem_dealloc(tmp)
endif

  if (CFG%orbspread) call orbspread_propint_free(inp)
  if (CFG%kurtosis)  call kurt_freeAO(CFG%KURT)
  if (CFG%Chargeloc) call mat_free(CFG%OrbLoc%SU)

  call LocalityMeasure(CFG,ls,cmo,ncore,nval,nvirt) 
    
    ! SANITY CHECK
    call mat_init(S,nbas,nbas)
    call mat_init(SC,nbas,nbas)
    call mat_init(CSC,nbas,nbas)
    CALL II_get_overlap(ls%lupri,ls%luerr,ls%setting,S)
    call mat_mul(S,CMO,'n','n',1E0_realk,0E0_realk,SC)
    call mat_mul(CMO,SC,'T','n',1E0_realk,0E0_realk,CSC)
    call mat_identity(SC)
    call mat_daxpy(-1E0_realk,SC,CSC)
    print*,'mat_sqnorm(C^T*S*C - I) =',mat_sqnorm2(CSC)/CSC%nrow
    IF(ABS(mat_sqnorm2(CSC)/CSC%nrow).GT.1.0E-15_realk)THEN
      write(ls%lupri,*) 'WARNING: ORBITALS NOT ORTHONORMAL!!! SOMETHING IS WRONG.' 
    ENDIF
    call mat_free(S)
    call mat_free(SC)
    call mat_free(CSC)


end subroutine optimloc


subroutine localize_davidson(CMO,m,orbspread_input,ls,CFG)
use orbspread_module
use charge_module
use davidson_settings
!use typedef
use typedeftype
use LSTIMING
use precision
use matrix_module, only: matrix
use matrix_operations 
!use matrix_util, only: matrix_exponential
!use matrix_module
!use matrix_operations
implicit none
type(RedSpaceItem) :: CFG
type(orbspread_data) :: orbspread_input
type(lsitem) :: ls
type(matrix) :: CMO
integer :: m

call davidson_reset(CFG)

if (CFG%orbspread) then
    call orbspread_localize_davidson(CFG,CMO,m,orbspread_input,ls)
    return
elseif (CFG%kurtosis) then
    call kurtosis_localize_davidson(CFG,CMO,m,ls)
    return
else
    call charge_localize_davidson(CFG,CMO,m,ls)
end if


end subroutine localize_davidson
!> \brief hessian linear transformation for power m orbital spread locality measure
!> \author B. Jansik
!> \date 2010
!> \param Hv linear transformation of H with trial vector V
!> \param V, trial vector
!> \param mu, level shift (H-muI)
!> \param norb, size of matrices (same as number of orbitals involved in localization)
!> \param orbspread_input structure holding orbspread related data
!!> \param m power
!!> \param spread2 vector of squared orbital spreads 
!!> \param R(3) matrix array holding XDIPLEN,YDIPLEN,ZDIPLEN components
!!> \param Q matrix holding sum XXSECMOM+YYSECMOM+ZZSECMOM
!!> \param tmpM(4) matrix array used as workspace
!> all parameters must be allocated prior to subroutine call
!> all type(matrix) arguments are of norb,norb size
subroutine orbspread_hesslin(Hv,V,mu,norb,orbspread_input)!m,spread2,R,Q,tmpM)
use orbspread_module
use charge_module
use davidson_settings
!use typedef
use typedeftype
use LSTIMING
use precision
use matrix_module, only: matrix
use matrix_operations 
!use matrix_util, only: matrix_exponential
!use matrix_module
!use matrix_operations
implicit none

Type(Matrix), intent(inout) :: Hv
Type(Matrix), intent(in)  :: V
real(realk), intent(in)   :: mu
integer, intent(in)       :: norb
type(orbspread_data), intent(in), target :: orbspread_input

integer       :: m
Type(Matrix)  :: R(3), RV(3)
Type(Matrix), pointer  ::  Q, G, QV ,tmpM
real(realk), pointer   :: spread2(:)
real(realk)  :: diagQV(norb), diagR(norb,3), diagRV(norb,3), tmp(norb)
integer      :: x,y,i

 !pointer assignments
 !stupid f90, no support for pointer arrays!
  do i=1,3
   call mat_clone(R(i),orbspread_input%R(i))
   call mat_clone(RV(i),orbspread_input%tmpM(i))
  enddo
  Q       => orbspread_input%Q
  QV      => orbspread_input%tmpM(4)
  tmpM    => orbspread_input%tmpM(4) !it's ok, QV will not be needed at that point
  G       => orbspread_input%G

  spread2 => orbspread_input%spread2

  m       =  orbspread_input%m


  !job
  call mat_mul(Q,V,'n','n',1E0_realk,0E0_realk,QV)

  call mat_extract_diagonal(diagQV,QV)


  do x=1, 3
  call mat_mul(R(x),V,'n','n',1E0_realk,0E0_realk,RV(x))
  call mat_extract_diagonal(diagRV(:,x),RV(x))
  call mat_extract_diagonal(diagR(:,x),R(x))
  enddo


  tmp = diagQV*(spread2**(m-2))
  call mat_zero(Hv)
  call mat_dmul(tmp,Q,'n',-4E0_realk*m*(m-1),0E0_realk,Hv)


  tmp =  (spread2**(m-1))
  call mat_dmul(tmp,QV,'t',-2E0_realk*m,1E0_realk,Hv)

  call mat_dmul(tmp,QV,'n',-2E0_realk*m,1E0_realk,Hv)

  do x=1, 3
  tmp = diagR(:,x)*diagQV*(spread2**(m-2))
  call mat_dmul(tmp,R(x),'n',8E0_realk*m*(m-1),1E0_realk,Hv)

  tmp = diagR(:,x)*diagRV(:,x)*(spread2**(m-2))
  call mat_dmul(tmp,Q,'n',8E0_realk*m*(m-1),1E0_realk,Hv)
 
     do y=1, 3
     tmp = diagR(:,x)*diagR(:,y)*diagRV(:,x)*(spread2**(m-2))
     call mat_dmul(tmp,R(y),'n',-16E0_realk*m*(m-1),1E0_realk,Hv)
     enddo

  tmp = diagRV(:,x)*(spread2**(m-1))
  call mat_dmul(tmp,R(x),'n',8E0_realk*m,1E0_realk,Hv)

  tmp = diagR(:,x)*(spread2**(m-1))
  call mat_dmul(tmp,RV(x),'t',4E0_realk*m,1E0_realk,Hv)

  call mat_dmul(tmp,RV(x),'n',4E0_realk*m,1E0_realk,Hv)

  enddo

  call mat_mul(V,G,'n','n',0.5E0_realk,1E0_realk,Hv)
  !call mat_mul(V,G,'n','n',1E0_realk,1E0_realk,Hv)

  call mat_trans(Hv,tmpM)
  call mat_daxpy(-1E0_realk,tmpM,Hv)

  !call mat_scal(0.5E0_realk,Hv)
  if (dabs(mu) > 1.0E-8_realk) call mat_daxpy(-mu,V,Hv)

end subroutine orbspread_hesslin

subroutine orbspread_precond(Xout,X,mu,inp)
use orbspread_module
use charge_module
use davidson_settings
!use typedef
use typedeftype
use LSTIMING
use precision
!use matrix_module
!use matrix_operations
use matrix_module, only: matrix
use matrix_operations
!use matrix_util, only: matrix_exponential
implicit none
type(Matrix), intent(inout) :: Xout
type(Matrix) :: X
real(realk),  intent(in) :: mu
type(orbspread_data), intent(in) :: inp
real(realk),pointer   :: tmp(:), tmpP(:)
integer                   :: i, ne
real(realk),pointer :: xvec(:),yvec(:)
type(matrix)  :: xtemp

  ne = Xout%nrow*Xout%ncol

  call mat_zero(Xout)
  
  select case(matrix_type)
  case(mtype_dense)

 
    do i=1,ne
       if (dabs(inp%P%elms(i)- mu) > 1d-8) Xout%elms(i) = X%elms(i)/(inp%P%elms(i) - mu)
    enddo
  case(mtype_scalapack)
    call mat_copy(1d0,X,Xout)
    call mat_hdiv(Xout,inp%P,mu)
  case default

    call mem_alloc(tmp,X%nrow*X%ncol)
    call mem_alloc(tmpP,inp%P%nrow*inp%P%ncol)
  
    call mat_to_full(X,1E0_realk,tmp)
    call mat_to_full(inp%P,1E0_realk,tmpP)

    do i=1,ne
    if (dabs(tmpP(i) - mu)> 1d-8) tmp(i) = tmp(i)/(tmpP(i) - mu)
    enddo


    call mat_set_from_full(tmp,1E0_realk,Xout)

    call mem_dealloc(tmp)
    call mem_dealloc(tmpP)

  end select

end subroutine orbspread_precond



!###### TESTING ROUTINES THAT ARE NOT COMPILED ########


#if 0
!> \brief unitest for orbspread_hesslin() subroutine
!> \author B. Jansik
!> \date 2010
!> \param passed 
!> passed shold be set to .true. otherwise orbspread_hesslin()
!> must be considered broken.
subroutine orbspread_hesslin_unitest(passed)
use orbspread_module
implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4

type(orbspread_data)   :: inp

type(Matrix) :: Hv,V,T, G
real(realk),parameter :: mu=-100E0_realk
integer :: i
 interface 
    subroutine orbspread_hesslin(Hv,V,mu,norb,orbspread_input)
      use decompMod
      use precision
      use matrix_module, only: matrix
      implicit none
      Type(Matrix), intent(inout) :: Hv
      Type(Matrix), intent(in)  :: V
      real(realk), intent(in)   :: mu
      integer, intent(in)       :: norb
      type(orbspread_data), intent(in), target :: orbspread_input
    end subroutine orbspread_hesslin
 end interface

!allocations
 call mat_init(Hv,norb,norb)
 call mat_init(V,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(T,norb,norb)
 call mat_init(G,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m

!initializations
V%elms=(/  0.00000E0_realk,   0.10165E0_realk,  -0.20779E0_realk,   0.80376E0_realk,&
&         -0.10165E0_realk,   0.00000E0_realk,   0.43667E0_realk,   0.67566E0_realk,&
&          0.20779E0_realk,  -0.43667E0_realk,   0.00000E0_realk,  -0.01383E0_realk,&
&         -0.80376E0_realk,  -0.67566E0_realk,   0.01383E0_realk,   0.00000E0_realk/)

inp%spread2=(/4.5307E0_realk,  4.6998E0_realk,  4.5653E0_realk,  4.6842E0_realk/)


inp%R(1)%elms=(/   -0.5491986E0_realk,  -0.0161635E0_realk,   0.0099889E0_realk,  -0.0634636E0_realk,&
&  -0.0161635E0_realk,  -2.2018273E0_realk,   0.0164245E0_realk,   0.0034423E0_realk,&
&   0.0099889E0_realk,   0.0164245E0_realk,   1.8516139E0_realk,  -0.0247713E0_realk,&
&  -0.0634636E0_realk,   0.0034423E0_realk,  -0.0247713E0_realk,  -1.0247656E0_realk/)

inp%R(2)%elms=(/    5.4993582E0_realk,  0.0159468E0_realk,  0.0328429E0_realk,  0.0018908E0_realk,&
&  0.0159468E0_realk,  8.1435615E0_realk,  0.0269154E0_realk,  0.0036474E0_realk,&
&  0.0328429E0_realk,  0.0269154E0_realk,  6.6766768E0_realk,  0.0184473E0_realk,&
&  0.0018908E0_realk,  0.0036474E0_realk,  0.0184473E0_realk,  6.2713034E0_realk/)

inp%R(3)%elms=(/   -5.568103E0_realk,  -0.029165E0_realk,  -0.085683E0_realk,   0.092566E0_realk,&
&  -0.029165E0_realk,  -0.452908E0_realk,  -0.012001E0_realk,  -0.063588E0_realk,&
&  -0.085683E0_realk,  -0.012001E0_realk,  -4.463905E0_realk,   0.103218E0_realk,&
&   0.092566E0_realk,  -0.063588E0_realk,   0.103218E0_realk,  -1.464168E0_realk/)

inp%Q%elms=(/   66.07905E0_realk,    0.34181E0_realk,    1.49184E0_realk,   -0.68992E0_realk,&
&    0.34181E0_realk,   76.07052E0_realk,    0.34397E0_realk,    0.46282E0_realk,&
&    1.49184E0_realk,    0.34397E0_realk,   72.49827E0_realk,   -0.56997E0_realk,&
&   -0.68992E0_realk,    0.46282E0_realk,   -0.56997E0_realk,   47.20738E0_realk/)

T%elms=(/ 0.0E0_realk,                 896.5073521804492E0_realk,  -371.1866122678854E0_realk, 3618.1303606658821E0_realk,&
&        -896.5073521804492E0_realk, 0.0E0_realk                ,  3826.0286713985975E0_realk, 1037.6687781704547E0_realk,&
&         371.1866122678854E0_realk, -3826.0286713985975E0_realk, 0.0E0_realk                , 74.9947733744852E0_realk,&
&       -3618.1303606658821E0_realk, -1037.6687781704547E0_realk, -74.9947733744852E0_realk  , 0.0E0_realk/)              


!test
 call orbspread_gradx(G,norb,inp)

 call orbspread_hesslin(Hv,V,mu,norb,inp)

 !Hv%elms=2E0_realk*Hv%elms
 write(6,*) 'Hesslin:'
 call mat_print(Hv,1,4,1,4,6)
 call mat_daxpy(-4E0_realk,Hv,T)

 passed = mat_sqnorm2(T).le. 1E-9_realk

!deallocations
 call mat_free(Hv)
 call mat_free(V)
 call mat_free(inp%Q)
 call mat_free(T)
 call mat_free(G)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_hesslin_unitest


!> \brief unitest for orbspread_gradx() subroutine
!> \author B. Jansik
!> \date 2010
!> \param passed 
!> passed shold be set to .true. otherwise orbspread_gradx()
!> must be considered broken.
subroutine orbspread_gradx_unitest(passed)
use orbspread_module
implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4

type(orbspread_data)   :: inp

type(Matrix) :: G,T
integer :: i

!allocations
 call mat_init(G,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(T,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m

inp%spread2=(/4.5307E0_realk,  4.6998E0_realk,  4.5653E0_realk,  4.6842E0_realk/)


inp%R(1)%elms=(/   -0.5491986E0_realk,  -0.0161635E0_realk,   0.0099889E0_realk,  -0.0634636E0_realk,&
&  -0.0161635E0_realk,  -2.2018273E0_realk,   0.0164245E0_realk,   0.0034423E0_realk,&
&   0.0099889E0_realk,   0.0164245E0_realk,   1.8516139E0_realk,  -0.0247713E0_realk,&
&  -0.0634636E0_realk,   0.0034423E0_realk,  -0.0247713E0_realk,  -1.0247656E0_realk/)

inp%R(2)%elms=(/    5.4993582E0_realk,  0.0159468E0_realk,  0.0328429E0_realk,  0.0018908E0_realk,&
&  0.0159468E0_realk,  8.1435615E0_realk,  0.0269154E0_realk,  0.0036474E0_realk,&
&  0.0328429E0_realk,  0.0269154E0_realk,  6.6766768E0_realk,  0.0184473E0_realk,&
&  0.0018908E0_realk,  0.0036474E0_realk,  0.0184473E0_realk,  6.2713034E0_realk/)

inp%R(3)%elms=(/   -5.568103E0_realk,  -0.029165E0_realk,  -0.085683E0_realk,   0.092566E0_realk,&
&  -0.029165E0_realk,  -0.452908E0_realk,  -0.012001E0_realk,  -0.063588E0_realk,&
&  -0.085683E0_realk,  -0.012001E0_realk,  -4.463905E0_realk,   0.103218E0_realk,&
&   0.092566E0_realk,  -0.063588E0_realk,   0.103218E0_realk,  -1.464168E0_realk/)

inp%Q%elms=(/   66.07905E0_realk,    0.34181E0_realk,    1.49184E0_realk,   -0.68992E0_realk,&
&    0.34181E0_realk,   76.07052E0_realk,    0.34397E0_realk,    0.46282E0_realk,&
&    1.49184E0_realk,    0.34397E0_realk,   72.49827E0_realk,   -0.56997E0_realk,&
&   -0.68992E0_realk,    0.46282E0_realk,   -0.56997E0_realk,   47.20738E0_realk/)

T%elms=(/  0.00000E0_realk,   -19.63628E0_realk,    -8.34807E0_realk,  106.23052E0_realk,&
&         19.63628E0_realk,     0.00000E0_realk,    18.56968E0_realk,   16.51622E0_realk,&
&          8.34807E0_realk,   -18.56968E0_realk,     0.00000E0_realk,   97.01746E0_realk,&
&       -106.23052E0_realk,   -16.51622E0_realk,   -97.01746E0_realk,    0.00000E0_realk/)


!test

 call orbspread_gradx(G,norb,inp)

 write(6,*) 'Gradx:'
 call mat_print(G,1,4,1,4,6)
 call mat_daxpy(-2E0_realk,G,T)

 passed = mat_sqnorm2(T).le. 1E-5_realk

!deallocations
 call mat_free(G)
 call mat_free(inp%Q)
 call mat_free(T)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_gradx_unitest

subroutine orbspread_precond_unitest(passed)
use orbspread_module
implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4
real(realk),parameter :: mu=-100E0_realk
type(orbspread_data)   :: inp

type(Matrix), target :: P,T,Tp
integer :: i, kl(2,1)
real(realk) :: emin(1)

!allocations
 call mat_init(P,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(T,norb,norb)
 call mat_init(Tp,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m
inp%spread2=(/4.5307E0_realk,  4.6998E0_realk,  4.5653E0_realk,  4.6842E0_realk/)


inp%R(1)%elms=(/   -0.5491986E0_realk,  -0.0161635E0_realk,   0.0099889E0_realk,  -0.0634636E0_realk,&
&  -0.0161635E0_realk,  -2.2018273E0_realk,   0.0164245E0_realk,   0.0034423E0_realk,&
&   0.0099889E0_realk,   0.0164245E0_realk,   1.8516139E0_realk,  -0.0247713E0_realk,&
&  -0.0634636E0_realk,   0.0034423E0_realk,  -0.0247713E0_realk,  -1.0247656E0_realk/)

inp%R(2)%elms=(/    5.4993582E0_realk,  0.0159468E0_realk,  0.0328429E0_realk,  0.0018908E0_realk,&
&  0.0159468E0_realk,  8.1435615E0_realk,  0.0269154E0_realk,  0.0036474E0_realk,&
&  0.0328429E0_realk,  0.0269154E0_realk,  6.6766768E0_realk,  0.0184473E0_realk,&
&  0.0018908E0_realk,  0.0036474E0_realk,  0.0184473E0_realk,  6.2713034E0_realk/)

inp%R(3)%elms=(/   -5.568103E0_realk,  -0.029165E0_realk,  -0.085683E0_realk,   0.092566E0_realk,&
&  -0.029165E0_realk,  -0.452908E0_realk,  -0.012001E0_realk,  -0.063588E0_realk,&
&  -0.085683E0_realk,  -0.012001E0_realk,  -4.463905E0_realk,   0.103218E0_realk,&
&   0.092566E0_realk,  -0.063588E0_realk,   0.103218E0_realk,  -1.464168E0_realk/)

inp%Q%elms=(/   66.07905E0_realk,    0.34181E0_realk,    1.49184E0_realk,   -0.68992E0_realk,&
&    0.34181E0_realk,   76.07052E0_realk,    0.34397E0_realk,    0.46282E0_realk,&
&    1.49184E0_realk,    0.34397E0_realk,   72.49827E0_realk,   -0.56997E0_realk,&
&   -0.68992E0_realk,    0.46282E0_realk,   -0.56997E0_realk,   47.20738E0_realk/)



!test

 call orbspread_precond_matrix(P,emin,kl,0,0E0_realk,norb,inp)

 inp%P => P

 T%elms=1E0_realk
 call orbspread_precond(Tp,T,mu,inp) 
 call mat_print(Tp,1,4,1,4,6)

!deallocations
 call mat_free(P)
 call mat_free(inp%Q)
 call mat_free(T)
 call mat_free(Tp)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_precond_unitest


subroutine exp_unitest(passed)
use matrix_util
implicit none
logical, intent(out)   :: passed
integer, parameter     :: norb=4
integer                :: noo, non

type(Matrix) :: X,expX,T

!allocations
 call mat_init(X,norb,norb)
 call mat_init(expX,norb,norb)
 call mat_init(T,norb,norb)
!0.344005

X%elms=(/   0.344005E0_realk,  0.370805E0_realk,  0.673547E0_realk,  0.686226E0_realk,&
&           0.031198E0_realk,  0.840471E0_realk,  0.605507E0_realk,  0.375608E0_realk,&
&           0.279060E0_realk,  0.628690E0_realk,  0.030451E0_realk,  0.115126E0_realk,&
&           0.675903E0_realk,  0.671164E0_realk,  0.102444E0_realk,  0.206692E0_realk/)

T%elms=(/  1.97286E0_realk,  1.62098E0_realk,  1.30758E0_realk,  1.29770E0_realk,&
&          0.45478E0_realk,  3.05118E0_realk,  1.20900E0_realk,  0.87865E0_realk,&
&          0.52325E0_realk,  1.34923E0_realk,  1.50395E0_realk,  0.50309E0_realk,&
&          1.12429E0_realk,  1.73292E0_realk,  0.83352E0_realk,  1.85123E0_realk/)

!test

 !call mat_no_of_matmuls(noo)

 call matrix_exponential(X,expX,1E-12_realk)

 !call mat_no_of_matmuls(non)

 !write(6,*) non-noo
 call mat_daxpy(-1E0_realk,expX,T)

 passed = mat_sqnorm2(T).le. 1E-9_realk

!deallocations
 call mat_free(X)
 call mat_free(expX)
 call mat_free(T)

end subroutine exp_unitest

subroutine orbspread_solver_unitest(passed)
use orbspread_module
!use decompMod
use ARHmodule

implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4

type(orbspread_data), target   :: inp

type(Matrix) :: Hv, G, X
real(realk),parameter :: mu=-1.32E0_realk
integer :: i

!solver related declarations
type(decompItem)   :: decomp
type(solverItem)   :: arh
type(debugItem)    :: debug
TYPE(modFIFO)      :: queue
 interface 
    subroutine orbspread_hesslin(Hv,V,mu,norb,orbspread_input)
      use decompMod
      use precision
      use matrix_module, only: matrix
      implicit none
      Type(Matrix), intent(inout) :: Hv
      Type(Matrix), intent(in)  :: V
      real(realk), intent(in)   :: mu
      integer, intent(in)       :: norb
      type(orbspread_data), intent(in), target :: orbspread_input
    end subroutine orbspread_hesslin
 end interface

!allocations
 call mat_init(Hv,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(G,norb,norb)
 call mat_init(X,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m

inp%spread2=(/0.16223E0_realk,  0.14987E0_realk,  0.39164E0_realk,  0.61443E0_realk/)


inp%R(1)%elms=(/  0.734535E0_realk,  0.584218E0_realk,  0.701755E0_realk,  0.064086E0_realk,&
&             0.853723E0_realk,  0.796857E0_realk,  0.305236E0_realk,  0.681963E0_realk,&
&             0.625375E0_realk,  0.441937E0_realk,  0.741858E0_realk,  0.748711E0_realk,&
&             0.766346E0_realk,  0.463687E0_realk,  0.927562E0_realk,  0.019981E0_realk/)

inp%R(2)%elms=(/  0.557369E0_realk,  0.435741E0_realk,  0.736332E0_realk,  0.455053E0_realk,&
&             0.027335E0_realk,  0.545388E0_realk,  0.923669E0_realk,  0.803679E0_realk,&
&             0.984998E0_realk,  0.065604E0_realk,  0.471317E0_realk,  0.816302E0_realk,&
&             0.662640E0_realk,  0.481126E0_realk,  0.147809E0_realk,  0.717182E0_realk/)

inp%R(3)%elms=(/  0.6461293E0_realk,  0.6788147E0_realk,  0.6815679E0_realk,  0.1965552E0_realk,&
&             0.2743679E0_realk,  0.7154769E0_realk,  0.3921278E0_realk,  0.2958226E0_realk,&
&             0.6670042E0_realk,  0.3111366E0_realk,  0.8163864E0_realk,  0.0074360E0_realk,&
&             0.7020067E0_realk,  0.8659539E0_realk,  0.7503724E0_realk,  0.0757745E0_realk/)

inp%Q%elms=(/0.047692E0_realk,  0.495820E0_realk,  0.258083E0_realk,  0.845362E0_realk,&
&        0.423167E0_realk,  0.148130E0_realk,  0.953802E0_realk,  0.640069E0_realk,&
&        0.588172E0_realk,  0.639629E0_realk,  0.395089E0_realk,  0.084721E0_realk,&
&        0.244598E0_realk,  0.104311E0_realk,  0.949004E0_realk,  0.040549E0_realk/)


!test
 call orbspread_gradx(G,norb,inp)


 call arh_set_default_config(arh)
 call decomp_set_default_config(decomp)
 arh%cfg_orbspread = .true.
 decomp%cfg_orbspread = .true.
 arh%orbspread_input => inp
 arh%cfg_arh_truncate = .false.
 arh%cfg_noprec = .false.

 call arh_crop_solver(decomp,arh,debug,G,2,X,queue)

 call orbspread_hesslin(Hv,X,arh%current_mu,norb,inp)


 call mat_daxpy(-1E0_realk,Hv,G)

 write(6,*) mat_sqnorm2(G)
 passed = mat_sqnorm2(G).le. 1E-9_realk

!deallocations
 call mat_free(Hv)
 call mat_free(X)
 call mat_free(inp%Q)
 call mat_free(G)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_solver_unitest

subroutine orbspread_solver_unitest2(passed)
use orbspread_module
!use decompMod
use ARHmodule

implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4

type(orbspread_data), target   :: inp

type(Matrix) :: Hv, G, X
real(realk),parameter :: mu=0E0_realk
integer :: i

!solver related declarations
type(decompItem)   :: decomp
type(solverItem)   :: arh
type(debugItem)    :: debug
TYPE(modFIFO)      :: queue
 interface 
    subroutine orbspread_hesslin(Hv,V,mu,norb,orbspread_input)
      use decompMod
      use precision
      use matrix_module, only: matrix
      implicit none
      Type(Matrix), intent(inout) :: Hv
      Type(Matrix), intent(in)  :: V
      real(realk), intent(in)   :: mu
      integer, intent(in)       :: norb
      type(orbspread_data), intent(in), target :: orbspread_input
    end subroutine orbspread_hesslin
 end interface

!allocations
 call mat_init(Hv,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(G,norb,norb)
 call mat_init(X,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m

inp%spread2=(/4.5307E0_realk,  4.6998E0_realk,  4.5653E0_realk,  4.6842E0_realk/)


inp%R(1)%elms=(/   -0.5491986E0_realk,  -0.0161635E0_realk,   0.0099889E0_realk,  -0.0634636E0_realk,&
&  -0.0161635E0_realk,  -2.2018273E0_realk,   0.0164245E0_realk,   0.0034423E0_realk,&
&   0.0099889E0_realk,   0.0164245E0_realk,   1.8516139E0_realk,  -0.0247713E0_realk,&
&  -0.0634636E0_realk,   0.0034423E0_realk,  -0.0247713E0_realk,  -1.0247656E0_realk/)

inp%R(2)%elms=(/    5.4993582E0_realk,  0.0159468E0_realk,  0.0328429E0_realk,  0.0018908E0_realk,&
&  0.0159468E0_realk,  8.1435615E0_realk,  0.0269154E0_realk,  0.0036474E0_realk,&
&  0.0328429E0_realk,  0.0269154E0_realk,  6.6766768E0_realk,  0.0184473E0_realk,&
&  0.0018908E0_realk,  0.0036474E0_realk,  0.0184473E0_realk,  6.2713034E0_realk/)

inp%R(3)%elms=(/   -5.568103E0_realk,  -0.029165E0_realk,  -0.085683E0_realk,   0.092566E0_realk,&
&  -0.029165E0_realk,  -0.452908E0_realk,  -0.012001E0_realk,  -0.063588E0_realk,&
&  -0.085683E0_realk,  -0.012001E0_realk,  -4.463905E0_realk,   0.103218E0_realk,&
&   0.092566E0_realk,  -0.063588E0_realk,   0.103218E0_realk,  -1.464168E0_realk/)

inp%Q%elms=(/   66.07905E0_realk,    0.34181E0_realk,    1.49184E0_realk,   -0.68992E0_realk,&
&    0.34181E0_realk,   76.07052E0_realk,    0.34397E0_realk,    0.46282E0_realk,&
&    1.49184E0_realk,    0.34397E0_realk,   72.49827E0_realk,   -0.56997E0_realk,&
&   -0.68992E0_realk,    0.46282E0_realk,   -0.56997E0_realk,   47.20738E0_realk/)



!test
 call orbspread_gradx(G,norb,inp)


 call arh_set_default_config(arh)
 call decomp_set_default_config(decomp)
 arh%cfg_orbspread = .true.
 decomp%cfg_orbspread = .true.
 arh%orbspread_input => inp
 arh%cfg_arh_truncate = .false.
 arh%cfg_noprec = .false.


 call arh_crop_solver(decomp,arh,debug,G,2,X,queue)

 call orbspread_hesslin(Hv,X,arh%current_mu,norb,inp)

 call mat_print(X,1,4,1,4,6)

 call mat_daxpy(-1E0_realk,Hv,G)

 write(6,*) mat_sqnorm2(G)
 passed = mat_sqnorm2(G).le. 1E-9_realk

!deallocations
 call mat_free(Hv)
 call mat_free(X)
 call mat_free(inp%Q)
 call mat_free(G)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_solver_unitest2



subroutine orbspread_precond_unitest2(passed)
use orbspread_module
!use decompMod
use ARHmodule

implicit none
logical, intent(out)   :: passed
integer,parameter      :: m=3,norb=4

type(orbspread_data), target   :: inp

type(Matrix) :: Hv, T, G, X
type(Matrix), pointer :: P
real(realk),parameter :: mu=0E0_realk
integer :: i,j, kl(2,1)
real(realk) :: val, emin(1)

!solver related declarations
type(decompItem)   :: decomp
type(solverItem)   :: arh
type(debugItem)    :: debug
TYPE(modFIFO)      :: queue
 interface 
    subroutine orbspread_hesslin(Hv,V,mu,norb,orbspread_input)
      use decompMod
      use precision
      use matrix_module, only: matrix
      implicit none
      Type(Matrix), intent(inout) :: Hv
      Type(Matrix), intent(in)  :: V
      real(realk), intent(in)   :: mu
      integer, intent(in)       :: norb
      type(orbspread_data), intent(in), target :: orbspread_input
    end subroutine orbspread_hesslin
 end interface

!allocations
 call mat_init(Hv,norb,norb)
 call mat_init(inp%Q,norb,norb)
 call mat_init(G,norb,norb)
 call mat_init(X,norb,norb)
 call mat_init(T,norb,norb)
 do i=1,3
  call mat_init(inp%R(i),norb,norb)
 enddo
 do i=1,4
  call mat_init(inp%tmpM(i),norb,norb)
 enddo

 call mem_alloc(inp%spread2,norb)

 inp%m = m

inp%spread2=(/0.16223,  0.14987,  0.39164,  0.61443/)

inp%R(1)%elms=(/   0.22097, 0.75410, 0.46831, 0.36425,&
&                  0.75410, 0.22471, 0.49422, 0.48281,&
&                  0.46831, 0.49422, 0.88116, 0.41692,&
&                  0.36425, 0.48281, 0.41692, 0.60770/)

inp%R(2)%elms=(/    0.27603,  0.79741,  0.46847,  0.15278,&
&                   0.79741,  0.74890,  0.59191,  0.94024,&
&                   0.46847,  0.59191,  0.35630,  0.60522,&
&                   0.15278,  0.94024,  0.60522,  0.95474/)

inp%R(3)%elms=(/   0.83232,  0.48356,  0.60922,  0.40515,&
&                  0.48356,  0.45738,  0.33015,  0.28682,&
&                  0.60922,  0.33015,  0.28448,  0.56644,&
&                  0.40515,  0.28682,  0.56644,  0.26361/)

inp%Q%elms=(/  0.14532,  0.47040,  0.67501,  0.47688,&
&              0.47040,  0.60246,  0.63225,  0.75969,&
&              0.67501,  0.63225,  0.90917,  0.55272,&
&              0.47688,  0.75969,  0.55272,  0.16080/)


!test
 call orbspread_gradx(G,norb,inp)

 do i=1,norb
  do j=1,norb
   call mat_scal(0E0_realk,X)

   call mat_create_elm(i,j,1E0_realk,X)

   call orbspread_hesslin(Hv,X,mu,norb,inp)

   call mat_get_elm(Hv,i,j,val)

   call mat_create_elm(i,j,val,T)
  enddo
 enddo

 call mat_scal(0.5E0_realk,T) 
 call mat_trans(T,inp%tmpM(1))
 call mat_daxpy(+1E0_realk,inp%tmpM(1),T)

 P => inp%tmpM(1)

 call orbspread_precond_matrix(P,emin,kl,0,mu,norb,inp)

 call mat_dotmul(T,P,1E0_realk,0E0_realk,X)

 call mat_print(T,1,4,1,4,6)
 call mat_print(P,1,4,1,4,6)
 write(6,*) mat_sqnorm2(X)
 passed = abs(mat_sqnorm2(X) -12E0_realk).le. 1E-9_realk

!deallocations
 call mat_free(Hv)
 call mat_free(X)
 call mat_free(T)
 call mat_free(inp%Q)
 call mat_free(G)
 do i=1,3
  call mat_free(inp%R(i))
 enddo
 do i=1,4
  call mat_free(inp%tmpM(i))
 enddo

 call mem_dealloc(inp%spread2)

end subroutine orbspread_precond_unitest2

#endif