!> @file 
!> Contains main SCF driver, some module wrappers and miscellaneous.
module profile_int
  
CONTAINS
!> \brief Driver for stand-alone f90 linear scaling SCF.
!> \author \latexonly T. Kj{\ae}rgaard, S. Reine  \endlatexonly
!> \date 2008-10-26
SUBROUTINE di_profile_lsint(ls,config,lupri,nbast)
  use profile_type
  use configurationType
  use direct_dens_util
  use initial_guess
  use lstiming
  use daltoninfo       
  use IntegralInterfaceMOD
  use II_XC_interfaceModule
  implicit none
  TYPE(lsitem)        :: ls
  type(configItem)    :: config
  integer             :: lupri,nbast
!
  Type(Matrix) :: H1,S,K,J,F,CMO
  Type(Matrix),target :: D,TMP
  Type(matrix),pointer :: Karray(:),Dvec(:)
  Type(matrixp),pointer :: Dvecp(:)
  integer             :: dens_lun,I,natoms,ndmat
  real(realk),pointer :: GRAD(:,:)
  LOGICAL             :: restart_from_dens,dens_exsist,restartTMP
  LOGICAL             :: fock_exsist,OnMaster
  real(realk)         :: TIMSTR,TIMEND,ts,te,EDFT(1),mx,Kfac,EDFTvec(30)
  real(realk),pointer :: eival(:),Evec(:)
#ifdef VAR_OMP
    integer, external :: OMP_GET_MAX_THREADS
#endif
    OnMaster = .TRUE.
    natoms = ls%input%MOLECULE%nAtoms
  WRITE(lupri,*)'============================================='
  WRITE(lupri,*)' '
  WRITE(lupri,*)'Profile Subroutine:'
#ifdef VAR_OMP
  write(lupri,*)'Number of threads: ', OMP_GET_MAX_THREADS()
#else
  write(lupri,*)'Number of threads:  1'
#endif
  WRITE(lupri,*)' '
  WRITE(lupri,*)'============================================='

  IF(config%prof%Overlap)THEN
     CALL LSTIMER('START',TIMSTR,TIMEND,lupri)
     call mat_init(S,nbast,nbast)
     CALL II_get_overlap(lupri,6,ls%setting,S)
     WRITE(lupri,*)'The Overlap dotproduct=',mat_dotproduct(S,S)
     call mat_free(S)
     CALL LSTIMER('PROFILE',TIMSTR,TIMEND,lupri)
     RETURN
  ENDIF

  INQUIRE(file='dens.restart',EXIST=dens_exsist) 
  restart_from_dens = dens_exsist
  call mat_init(D,nbast,nbast)
  if(restart_from_dens)then
     !read and use density matrix
     restartTMP = config%diag%cfg_restart
     config%diag%cfg_restart = .TRUE.
     call get_initial_dens(H1,S,D,ls,config)
     config%diag%cfg_restart = restartTMP
  else
     !build and write density matrix
     CALL mat_init(H1,nbast,nbast)
     CALL mat_init(S,nbast,nbast)
     CALL II_get_overlap(lupri,6,ls%setting,S)
     write(lupri,*) 'QQQ S:',mat_trab(S,S)
     CALL II_get_h1(lupri,6,ls%setting,H1)
     write(lupri,*) 'QQQ h:',mat_trab(H1,H1)
     call get_initial_dens(H1,S,D,ls,config)
     write(lupri,*) 'QQQ D:',mat_trab(D,D)
     !** Write density to disk for possible restart
     dens_lun = -1
     call lsopen(dens_lun,'dens.restart','UNKNOWN','UNFORMATTED')
     rewind dens_lun
     call mat_write_to_disk(dens_lun,D,OnMaster)
     call mat_write_info_to_disk(dens_lun,config%decomp%cfg_gcbasis)
     call lsclose(dens_lun,'KEEP')
     WRITE(lupri,*)'Succesfully wrote valid Density Matrix to Disk'
     print*,'Succesfully wrote valid Density Matrix to Disk'
     CALL mat_free(H1)
     CALL mat_free(S)
  endif
     
!#ifdef VAR_OMP
!  DO I = 1,2
  I=1
   IF(I.EQ. 1)THEN
      write(lupri,*)'__________________________________________________________________'

!      write(lupri,*)'Starting Profile Using: ', OMP_GET_MAX_THREADS(),' threads'
      write(lupri,*)'__________________________________________________________________'
   ELSE
      write(lupri,*)'__________________________________________________________________'
      write(lupri,*)'Starting Profile Using: 1 thread'
      write(lupri,*)'__________________________________________________________________'
      ls%setting%scheme%noOMP = .TRUE.
   ENDIF
!#else
!  I=2
!  write(lupri,*)'Number of threads:  1'
!#endif
  CALL LSTIMER('START',TIMSTR,TIMEND,lupri)
  CALL LSTIMER('START',ts,te,lupri)
  IF(config%prof%Coulomb)THEN
     call mat_init(J,nbast,nbast)
     call II_get_coulomb_mat(LUPRI,6,ls%SETTING,D,J,1)
     WRITE(lupri,*)'Coulomb energy, mat_dotproduct(D,J)=',mat_dotproduct(D,J)
     call mat_free(J)
     CALL LSTIMER('J-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%CoulombEcont)THEN
     call mem_alloc(Dvec,10)
     call mem_alloc(Evec,10)
     do I = 1,10
        call mat_init(Dvec(I),nbast,nbast)
        call mat_assign(Dvec(I),D)
     enddo
     ls%SETTING%SCHEME%intTHRESHOLD = &
          & ls%SETTING%SCHEME%THRESHOLD*ls%SETTING%SCHEME%J_THR!*modThresh
     CALL II_get_CoulombEcont(lupri,6,ls%setting,Dvec,Evec,10)
     WRITE(lupri,*)'Coulomb energy =',Evec(10)
     WRITE(*,*)'Coulomb energy =',Evec(10)
     CALL LSTIMER('J-ECONT',ts,te,lupri)
     do I = 1,10
        call mat_free(Dvec(I))
     enddo
     call mem_dealloc(Dvec)
     call mem_dealloc(Evec)
  ENDIF
  IF(config%prof%Exchange)THEN
     call mat_init(K,nbast,nbast)
     call mat_zero(K)
     ndmat = 1
     CALL II_get_exchange_mat(lupri,6,ls%setting,D,ndmat,.TRUE.,K)
     WRITE(lupri,*)'Exchange energy, mat_dotproduct(D,K)=',mat_dotproduct(D,K)
     WRITE(6,*)'Exchange energy, mat_dotproduct(D,K)=',mat_dotproduct(D,K)
     call mat_free(K)
     CALL LSTIMER('K-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%ExchangeEcont)THEN
     call mem_alloc(Dvec,30)
     call mem_alloc(Evec,30)
     do I = 1,30
        call mat_init(Dvec(I),nbast,nbast)
        call mat_assign(Dvec(I),D)
     enddo
     Kfac = ls%SETTING%SCHEME%exchangeFactor
     ls%SETTING%SCHEME%intTHRESHOLD = &
          & ls%SETTING%SCHEME%THRESHOLD*ls%SETTING%SCHEME%K_THR*(1.0E0_realk/Kfac)!*modThresh
     ndmat = 30
     CALL II_get_exchangeEcont(lupri,6,ls%setting,Dvec,Evec,ndmat)
     WRITE(lupri,*)'Exchange energy, mat_dotproduct(D,K)=',Evec(1)
     WRITE(6,*)'Exchange energy, mat_dotproduct(D,K)=',Evec(1)
     CALL LSTIMER('K-ECONT',ts,te,lupri)
     do I = 1,30
        call mat_free(Dvec(I))
     enddo
     call mem_dealloc(Dvec)
     call mem_dealloc(Evec)
  ENDIF
  IF(config%prof%Exchangegrad)THEN
     call mem_alloc(GRAD,3,natoms)
     call mem_alloc(Dvecp,30)
     call mat_init(TMP,nbast,nbast)
     call mat_assign(TMP,D)
     !we need a nonsym matrix
     TMP%elms(2) = TMP%elms(2)+0.7654E0_realk
     TMP%elms(nbast) = TMP%elms(nbast)-0.7654E0_realk
     TMP%elms(2*nbast-1) = TMP%elms(nbast)+0.2654E0_realk
     TMP%elms(nbast*nbast-1) = TMP%elms(nbast)-0.3654E0_realk
     TMP%elms((nbast-1)*nbast-1) = TMP%elms(nbast)-0.4654E0_realk
     do I = 1,30
        Dvecp(I)%p => TMP
     enddo
     CALL II_get_K_gradient(grad,Dvecp,Dvecp,30,30,ls%setting,lupri,6)
     WRITE(lupri,*)'Exchange gradX=',grad(1,1)
     WRITE(lupri,*)'Exchange gradX=',grad(2,1)
     WRITE(lupri,*)'Exchange gradX=',grad(3,1)
     WRITE(6,*)'Exchange gradX=',grad(1,1)
     WRITE(6,*)'Exchange gradX=',grad(2,1)
     WRITE(6,*)'Exchange gradX=',grad(3,1)
     call mem_dealloc(GRAD)
     call mem_dealloc(Dvecp)
     CALL LSTIMER('KG-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%ExchangeManyD)THEN
     call mem_alloc(Karray,30)
     call mem_alloc(Dvec,30)
     do I = 1,30
        call mat_init(Karray(I),nbast,nbast)
        call mat_zero(Karray(I))
        call mat_init(Dvec(I),nbast,nbast)
        call mat_assign(Dvec(I),D)
     enddo
     CALL II_get_exchange_mat(lupri,6,ls%setting,Dvec,30,.TRUE.,Karray)
     WRITE(lupri,*)'Exchange energy, mat_dotproduct(D1,K1)=',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(lupri,*)'Exchange energy, mat_dotproduct(D2,K2)=',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(6,*)'Exchange energy, mat_dotproduct(D1,K1)  =',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(6,*)'Exchange energy, mat_dotproduct(D2,K2)  =',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(6,*)'Exchange energy, mat_dotproduct(D3,K3)  =',mat_dotproduct(Dvec(3),Karray(3))
     WRITE(6,*)'Exchange energy, mat_dotproduct(D4,K4)  =',mat_dotproduct(Dvec(4),Karray(4))
     WRITE(6,*)'Exchange energy, mat_dotproduct(D30,K30)=',mat_dotproduct(Dvec(30),Karray(30))
     do I = 1,30
        call mat_free(Karray(I))
        call mat_free(Dvec(I))
     enddo
     call mem_dealloc(Karray)
     call mem_dealloc(Dvec)
     CALL LSTIMER('K-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%XC)THEN
     call mat_init(F,nbast,nbast)
     call mat_zero(F)
     CALL II_get_xc_Fock_mat(LUPRI,6,LS%SETTING,nbast,D,F,EDFT,1)
     WRITE(lupri,*)'Exchange Correlation mat_dotproduct(D,F)=',mat_dotproduct(D,F)
     WRITE(lupri,*)'Exchange Correlation energy =',EDFT(1)
     CALL LSTIMER('XC1-PROF ',ts,te,lupri)
     call mat_zero(F)
     CALL II_get_xc_Fock_mat(LUPRI,6,LS%SETTING,nbast,D,F,EDFT,1)
     WRITE(lupri,*)'Exchange Correlation mat_dotproduct(D,F)=',mat_dotproduct(D,F)
     WRITE(lupri,*)'Exchange Correlation energy =',EDFT(1)
     call mat_free(F)
     CALL LSTIMER('XC2-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%XCLINRSP)THEN
     call mem_alloc(Karray,30)
     call mem_alloc(Dvec,30)
     do I = 1,30
        call mat_init(Karray(I),nbast,nbast)
        call mat_zero(Karray(I))
        call mat_init(Dvec(I),nbast,nbast)
        call mat_assign(Dvec(I),D)
     enddo
     CALL II_get_xc_linrsp(LUPRI,6,LS%SETTING,nbast,Dvec,D,Karray,30)
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(3),Karray(3))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(30),Karray(30))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(3),Karray(3))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(30),Karray(30))
     CALL LSTIMER('XC3-PROF ',ts,te,lupri)
     do I = 1,30
        call mat_zero(Karray(I))
     enddo
     CALL II_get_xc_linrsp(LUPRI,6,LS%SETTING,nbast,Dvec,D,Karray,30)
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(3),Karray(3))
     WRITE(lupri,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(30),Karray(30))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(1),Karray(1))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(2),Karray(2))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(3),Karray(3))
     WRITE(6,*)'Exchange Correlation linrsp =',mat_dotproduct(Dvec(30),Karray(30))
     CALL LSTIMER('XC4-PROF ',ts,te,lupri)
     do I = 1,30
        call mat_free(Karray(I))
        call mat_free(Dvec(I))
     enddo
     call mem_dealloc(Karray)
     call mem_dealloc(Dvec)
  ENDIF
  IF(config%prof%XCFGRAD)THEN
     call mem_alloc(GRAD,3,natoms)
     CALL II_get_xc_geoderiv_FxDgrad(LUPRI,6,LS%SETTING,nbast,D,D,grad,natoms)
     WRITE(lupri,*)'Exchange Correlation gradX =',grad(1,1)
     WRITE(lupri,*)'Exchange Correlation gradY =',grad(2,1)
     WRITE(lupri,*)'Exchange Correlation gradZ =',grad(3,1)
     CALL LSTIMER('XC5-PROF ',ts,te,lupri)
     CALL II_get_xc_geoderiv_FxDgrad(LUPRI,6,LS%SETTING,nbast,D,D,grad,natoms)
     WRITE(lupri,*)'Exchange Correlation gradX =',grad(1,1)
     WRITE(lupri,*)'Exchange Correlation gradY =',grad(2,1)
     WRITE(lupri,*)'Exchange Correlation gradZ =',grad(3,1)
     call mem_dealloc(GRAD)
     CALL LSTIMER('XC6-PROF ',ts,te,lupri)
  ENDIF
  IF(config%prof%XCENERGY)THEN
     call mem_alloc(Dvec,30)
     do I = 1,30
        call mat_init(Dvec(I),nbast,nbast)
        call mat_assign(Dvec(I),D)
     enddo
     CALL II_get_xc_energy(LUPRI,6,LS%SETTING,nbast,Dvec,EDFTvec,30)
     WRITE(lupri,*)'Exchange Correlation energy =',EDFT(1)
     CALL LSTIMER('XC7-PROF ',ts,te,lupri)
     CALL II_get_xc_energy(LUPRI,6,LS%SETTING,nbast,Dvec,EDFTvec,30)
     WRITE(lupri,*)'Exchange Correlation energy =',EDFT(1)
     CALL LSTIMER('XC8-PROF ',ts,te,lupri)
     do I = 1,30
        call mat_free(Dvec(I))
     enddo
     call mem_dealloc(Dvec)
  ENDIF
  IF(config%prof%Fock)THEN
     call mat_init(F,nbast,nbast)
     call II_get_Fock_mat(LUPRI,6,ls%SETTING,D,.true.,F,1,.FALSE.)
     WRITE(lupri,*)'Fock energy, mat_dotproduct(D,F)=',mat_dotproduct(D,F)
     call mat_free(F)
     CALL LSTIMER('Fock-PROF ',ts,te,lupri)
  ENDIF
  IF(I.EQ. 2)THEN
     CALL LSTIMER('PROFILE',TIMSTR,TIMEND,lupri)
  ELSE
     CALL LSTIMER('OMPPROF',TIMSTR,TIMEND,lupri)
  ENDIF
!#ifdef VAR_OMP
!  ENDDO
!#endif
  call mat_free(D)
  call stats_mem(lupri)
     
END SUBROUTINE DI_PROFILE_LSINT

end module profile_int