

MODULE PBC_kspce_rspc_operations
USE precision
USE lattice_type
USE lattice_vectors
USE pbc_msc

CONTAINS

SUBROUTINE pbc_rspc_to_kspc_mat(Armat,Bkmat,nbast,kvec,oper)
IMPLICIT NONE
!DUMMY VARIABLES
TYPE(lvec_list_t), intent(IN)  :: Armat
TYPE(Bzgrid_t), intent(INOUT) :: Bkmat
REAL(realk), intent(IN)        :: kvec(3)
INTEGER, intent(IN)            :: nbast,oper
                    !LOCAL VARIABLES
INTEGER                       :: layer,l1,l2,l3
REAL(realk)                   :: phase1,phase2,phase3
COMPLEX(complexk)             :: phase

 DO layer = 1, size(Armat%lvec)
   l1=int(Armat%lvec(layer)%lat_coord(1))
   l2=int(Armat%lvec(layer)%lat_coord(2))
   l3=int(Armat%lvec(layer)%lat_coord(3))

   if(oper .eq. 2) then !Fock matrix

     if((abs(l1) .le. Armat%fc1 .and. abs(l2) .le. Armat%fc2) .and. abs(l3) .le. Armat%fc3)then
       phase1=kvec(1)*Armat%lvec(layer)%std_coord(1)
       phase2=kvec(2)*Armat%lvec(layer)%std_coord(2)
       phase3=kvec(3)*Armat%lvec(layer)%std_coord(3)
       phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       Bkmat%fck%zelms=Bkmat%fck%zelms+Armat%lvec(layer)%oper(2)%elms*exp(phase)
     endif

   elseif(oper .eq. 1) then
   !Overlap
   !and oneparticl

     if((abs(l1) .le. Armat%oneop1 .and. abs(l2) .le. Armat%oneop2) .and. abs(l3) .le. Armat%oneop3)then
       phase1=kvec(1)*Armat%lvec(layer)%std_coord(1)
       phase2=kvec(2)*Armat%lvec(layer)%std_coord(2)
       phase3=kvec(3)*Armat%lvec(layer)%std_coord(3)
       phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       Bkmat%Smat%zelms=Bkmat%Smat%zelms+Armat%lvec(layer)%oper(1)%elms*exp(phase)
     endif
     
   elseif(oper .eq. 4) then
   !Coulomb

     if((abs(l1) .le. Armat%col1 .and. abs(l2) .le. Armat%col2) .and. abs(l3) .le. Armat%col3)then
       phase1=kvec(1)*Armat%lvec(layer)%std_coord(1)
       phase2=kvec(2)*Armat%lvec(layer)%std_coord(2)
       phase3=kvec(3)*Armat%lvec(layer)%std_coord(3)
       phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       Bkmat%fck%zelms=Bkmat%fck%zelms+Armat%lvec(layer)%oper(1)%elms*exp(phase)
     endif

   elseif(oper .eq. 5) then
   !exchange

     if((abs(l1) .le. Armat%Kx1 .and. abs(l2) .le. Armat%Kx2) .and. abs(l3) .le. Armat%Kx3)then
       phase1=kvec(1)*Armat%lvec(layer)%std_coord(1)
       phase2=kvec(2)*Armat%lvec(layer)%std_coord(2)
       phase3=kvec(3)*Armat%lvec(layer)%std_coord(3)
       phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       Bkmat%fck%zelms=Bkmat%fck%zelms+Armat%lvec(layer)%oper(1)%elms*exp(phase)
     endif
   endif

 ENDDO


END SUBROUTINE pbc_rspc_to_kspc_mat

SUBROUTINE pbc_trans_mat_to_kspc(real_mat,numvecs,ll,Bkmat,nbast,kvec,realcut)
IMPLICIT NONE
!DUMMY VARIABLES
INTEGER,INTENT(IN)        :: numvecs
TYPE(lvec_list_t),INTENT(IN) :: ll
TYPE(matrix), intent(IN)  :: real_mat(numvecs)
TYPE(Bzgrid_t), intent(INOUT) :: Bkmat
REAL(realk), intent(IN)        :: kvec(3)
INTEGER, intent(IN)            :: nbast,realcut(3)
                    !LOCAL VARIABLES
LOGICAL                       :: innegligible
INTEGER                       :: layer,l1,l2,l3
REAL(realk)                   :: phase1,phase2,phase3
COMPLEX(complexk)             :: phase

 DO layer = 1, numvecs
   l1=int(ll%lvec(layer)%lat_coord(1))
   l2=int(ll%lvec(layer)%lat_coord(2))
   l3=int(ll%lvec(layer)%lat_coord(3))

   innegligible= (abs(l1) .le. realcut(1) .and.abs(l2) .le. realcut(2) )
   innegligible=(innegligible .and. abs(l3) .le. realcut(3) )
                  
   if(innegligible) then
     phase1=kvec(1)*ll%lvec(layer)%std_coord(1)
     phase2=kvec(2)*ll%lvec(layer)%std_coord(2)
     phase3=kvec(3)*ll%lvec(layer)%std_coord(3)
     phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
     Bkmat%Smat%zelms=Bkmat%Smat%zelms+real_mat(layer)%elms*exp(phase)
   endif
 ENDDO

END SUBROUTINE pbc_trans_mat_to_kspc

SUBROUTINE transformk_2_realmat(kdep_tmp,bz,rspcdensity,&
                                nbast,lattindex,lupri)
  IMPLICIT NONE
  INTEGER,INTENT(IN) :: nbast,lupri
  TYPE(BZgrid_t),intent(in) :: bz
  TYPE(pbc_elstr_t),INTENT(IN) :: kdep_tmp(bz%nk)
  REAL(realk),intent(IN) :: lattindex(3)
  REAL(realk),INTENT(INOUT) :: rspcdensity(nbast,nbast)
  !LOCAL VARIABLES
  INTEGER :: kpt,i,j,k
  real(realk) :: phase1,phase2,phase3,kvec(3)
  !REAL(realk) :: PI=3.14159265358979323846D0
  COMPLEX(COMPLEXK) :: phase
  COMPLEX(COMPLEXK) :: work(nbast,nbast)

  work(:,:) = CMPLX(0.d0,0d0,complexk)
  

  DO kpt=1,bz%nk
     !write(*,*) lattindex(1),lattindex(2),lattindex(3)
     call pbc_get_kpoint(kpt,kvec)
     phase1=real(lattindex(1)*kvec(1),realk)
     phase2=real(lattindex(2)*kvec(2),realk)
     phase3=real(lattindex(3)*kvec(3),realk)
     phase=CMPLX(0.,(phase1+phase2+phase3),complexk)
     if((lattindex(1) .eq. 0.and.lattindex(2) .eq. 0) .and. lattindex(3) .eq.0)&
     &phase=cmplx(0d0,0d0,complexk)
     if(lattindex(1) .eq. 1) write(lupri,*) 'phase',exp(phase),bz%kpnt(kpt)%lambda(1)
       do i=1,nbast
        do j=1,nbast
           work(i,j)=work(i,j)+kdep_tmp(kpt)%kddensitymat(i,j)*exp(phase)*&
           &bz%kpnt(kpt)%weight/BZ%NK_nosym
           !write(lupri,*) 'BZ%NK_nosym',BZ%NK_nosym
        enddo
       enddo
  ENDDO
  !write(lupri,*) 'bz%nk_nosym',bz%nk_nosym
!  write(lupri,*) 'complex density realspace',lattindex(1)
!  call write_zmatrix(work,nbast,nbast,lupri)
!  STOP

  k=0
  do i=1,nbast
   do j=1,nbast
    if(abs(DIMAG(work(j,i))) .gt. 1E-5) then
      write(*,*) 'ERROR, complex realspace density:', work(i,j),i,j
      write(lupri,*) 'ERROR, complex realspace density:',&
      work(i,j),i,j,int(lattindex(1))
      call LSQUIT('COMPLEX REALSPACE density',lupri)
    endif
    rspcdensity(i,j)=real(work(i,j),realk)
   enddo
  enddo

!  write(lupri,*) 'real density realspace',lattindex(1)
!  call write_matrix(rspcdensity,nbast,nbast,lupri)
  !write(lupri,*) 'density'
  !write(lupri,*) rspcdensity
  !write(*,*) rspcdensity
  !stop

END SUBROUTINE transformk_2_realmat


!TRANSFORMS TO D^0l
SUBROUTINE kspc_2_rspc_loop_k(density,kmat,ll,kvec,weight_k,volbz,nbast)
  IMPLICIT NONE
  INTEGER,intent(in)           :: nbast
  integer                      :: volbz
  COMPLEX(complexk),intent(in) :: kmat(nbast,nbast)
  TYPE(lvec_list_t),intent(IN) :: ll
  TYPE(matrix), intent(inout)  :: density(size(ll%lvec))
  REAL(realk),intent(in)       :: kvec(3),weight_k
                    !LOCAL Variables
  TYPE(matrix)                 :: tmp_density
  REAL(realk)                  :: work(nbast,nbast)
  REAL(realk)                  :: phase1,phase2,phase3
  COMPLEX(complexk)            :: phase
  INTEGER                      :: layer,i,j
  INTEGER                      :: l1,l2,l3


  call mat_init(tmp_density,nbast,nbast)
  DO layer = 1,size(ll%lvec)
     l1=int(ll%lvec(layer)%lat_coord(1))
     l2=int(ll%lvec(layer)%lat_coord(2))
     l3=int(ll%lvec(layer)%lat_coord(3))
     if((abs(l1) .le. ll%ndmat .and. abs(l2) .le. ll%ndmat)&
     & .and. abs(l3) .le. ll%ndmat) then

     call mat_zero(tmp_density)

     phase1=kvec(1)*ll%lvec(layer)%std_coord(1)
     phase2=kvec(2)*ll%lvec(layer)%std_coord(2)
     phase3=kvec(3)*ll%lvec(layer)%std_coord(3)
     phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       Do i=1,nbast
        Do j=1,nbast
         
         work(i,j)=real(kmat(i,j)*exp(phase)*weight_k/volbz,realk)

        ENDDO
       ENDDO
       !call write_matrix(work,nbast,nbast)
       call mat_set_from_full(work,1.0_realk,tmp_density)
       call mat_daxpy(1.D0,tmp_density,density(layer))
     endif

  enddo
  call mat_free(tmp_density)


END SUBROUTINE kspc_2_rspc_loop_k
!Get the one particle part of the energy matrix for one k value
SUBROUTINE pbc_get_onep_matrix(Aop,energy1_k,nrows,ncols,nlats,kvec,diis)
IMPLICIT NONE
INTEGER,INTENT(IN) :: nrows,ncols,nlats
TYPE(lvec_list_t)   :: Aop
COMPLEX(COMPLEXK),INTENT(INOUT) :: energy1_k(nrows,ncols)
CHARACTER(len=12)          :: diis
REAL(realk),intent(in)     :: kvec(3)
!LOCAL Variables
TYPE(matrix)      :: h_1,h1_tmp
REAL(realk)       :: h_1full(nrows,ncols)
INTEGER :: layer,l1,l2,l3
INTEGER :: IOS,FILELEN,iunit
CHARACTER(len=24)          :: filename
CHARACTER(len=5)  :: stl1,stl2,stl3
LOGICAL :: fileexists
REAL(realk)                   :: phase1,phase2,phase3
COMPLEX(complexk)             :: phase

call mat_init(h_1,nrows,ncols)
call mat_init(h1_tmp,nrows,ncols)
Do layer=1,nlats
   l1=int(Aop%lvec(layer)%lat_coord(1))
   l2=int(Aop%lvec(layer)%lat_coord(2))
   l3=int(Aop%lvec(layer)%lat_coord(3))
   iunit=-1

   if((abs(l1) .le. Aop%oneop1 .and. abs(l2) .le. Aop%oneop2)&
   & .and. abs(l3) .le. Aop%oneop3)then
       !kinetic
       call mat_zero(h_1)
       call mat_zero(h1_tmp)

       write(stl1,'(I5)')  l1
       write(stl2,'(I5)')  l2
       write(stl3,'(I5)')  l3
       stl1=adjustl(stl1)
       stl2=adjustl(stl2)
       stl3=adjustl(stl3)


       filename = trim(diis)//trim(adjustl(Aop%opdat(2)%basename))//'_'//trim(stl1)//'_'//trim(stl2)//'_'//trim(stl3)
       
       filename=adjustl(filename)
       filename=trim(filename)
       FILELEN=len(filename)
       INQUIRE(FILE=filename(1:FILELEN),EXIST=fileexists,IOSTAT=IOS)
       IF(fileexists) then
         call LSOPEN(iunit,filename,'OLD','UNFORMATTED')

         !We write the matrix to a binary file
         call read_binary_matrix(h1_tmp,nrows,ncols,iunit)

         call LSCLOSE(iunit,'KEEP')
         call mat_daxpy(1.0_realk,h1_tmp,h_1)
         call mat_zero(h1_tmp)
       endif
       !nuclear attraction
       filename = trim(diis)//trim(adjustl(Aop%opdat(3)%basename))//'_'//trim(stl1)//'_'//trim(stl2)//'_'//trim(stl3)
       
       filename=adjustl(filename)
       filename=trim(filename)
       FILELEN=len(filename)
       INQUIRE(FILE=filename(1:FILELEN),EXIST=fileexists,IOSTAT=IOS)
       IF(fileexists) then
         call LSOPEN(iunit,filename,'OLD','UNFORMATTED')

         !We write the matrix to a binary file
         call read_binary_matrix(h1_tmp,nrows,ncols,iunit)

         call LSCLOSE(iunit,'KEEP')
         call mat_daxpy(1.0_realk,h1_tmp,h_1)
         call mat_zero(h1_tmp)
         call mat_to_full(h_1,1D0,h_1full)
       phase1=kvec(1)*Aop%lvec(layer)%std_coord(1)
       phase2=kvec(2)*Aop%lvec(layer)%std_coord(2)
       phase3=kvec(3)*Aop%lvec(layer)%std_coord(3)
       phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
       energy1_k=energy1_k+h_1full*exp(phase)
       endif
   endif
ENDDO


call mat_free(h1_tmp)
call mat_free(h_1)
END SUBROUTINE pbc_get_onep_matrix


!Get the two particle part of the energy matrix for one k value
SUBROUTINE pbc_get_twop_matrix(Aop,energy2_k,nrows,ncols,nlats,kvec,diis)
IMPLICIT NONE
TYPE(lvec_list_t),INTENT(INOUT) :: Aop
INTEGER,INTENT(IN) :: nrows,ncols,nlats
COMPLEX(COMPLEXK),INTENT(INOUT) :: energy2_k(nrows,ncols)
REAL(realk),intent(in)     :: kvec(3)
CHARACTER(len=12)          :: diis
!LOCAL Variables
TYPE(matrix) :: T2_tmp,T2
REAL(realk)  :: T2full(nrows,ncols)
INTEGER :: layer,l1,l2,l3
INTEGER :: IOS,FILELEN,iunit
CHARACTER(len=24)          :: filename
CHARACTER(len=5)  :: stl1,stl2,stl3
LOGICAL :: fileexists
REAL(realk)                   :: phase1,phase2,phase3
COMPLEX(complexk)             :: phase

call mat_init(T2_tmp,nrows,ncols)
call mat_init(T2,nrows,ncols)

Do layer=1,nlats
   l1=int(Aop%lvec(layer)%lat_coord(1))
   l2=int(Aop%lvec(layer)%lat_coord(2))
   l3=int(Aop%lvec(layer)%lat_coord(3))
   call mat_zero(T2)
   call mat_zero(T2_tmp)

   write(stl1,'(I5)')  l1
   write(stl2,'(I5)')  l2
   write(stl3,'(I5)')  l3
   stl1=adjustl(stl1)
   stl2=adjustl(stl2)
   stl3=adjustl(stl3)

   iunit=-1
   if((abs(l1) .le. Aop%col1 .and. abs(l2) .le. Aop%col2)& !col refers J-mat
  & .and. abs(l3) .le. Aop%col3)then
     !Coulomb matrix

       filename = trim(diis)//trim(adjustl(Aop%opdat(4)%basename))//'_'//trim(stl1)//'_'//trim(stl2)//'_'//trim(stl3)
       
       filename=adjustl(filename)
       filename=trim(filename)
       FILELEN=len(filename)
       INQUIRE(FILE=filename(1:FILELEN),EXIST=fileexists,IOSTAT=IOS)
       IF(fileexists) then
         call LSOPEN(iunit,filename,'OLD','UNFORMATTED')

         !We write the matrix to a binary file
         call read_binary_matrix(T2_tmp,nrows,ncols,iunit)

         call LSCLOSE(iunit,'KEEP')
         call mat_daxpy(1.0_realk,T2_tmp,T2)
         call mat_zero(T2_tmp)
       endif
   endif
  
   if((abs(l1) .le. Aop%Kx1 .and. abs(l2) .le. Aop%Kx2)&
  & .and. abs(l3) .le. Aop%Kx3)then

     !Exact exchange matrix
       filename = trim(diis)//trim(adjustl(Aop%opdat(4)%basename))//'_'//trim(stl1)//'_'//trim(stl2)//'_'//trim(stl3)
       
       filename=adjustl(filename)
       filename=trim(filename)
       FILELEN=len(filename)
       INQUIRE(FILE=filename(1:FILELEN),EXIST=fileexists,IOSTAT=IOS)
       IF(fileexists) then
         call LSOPEN(iunit,filename,'OLD','UNFORMATTED')

         !We write the matrix to a binary file
         call read_binary_matrix(T2_tmp,nrows,ncols,iunit)

         call LSCLOSE(iunit,'KEEP')
         call mat_daxpy(1.0_realk,T2_tmp,T2)
         call mat_zero(T2_tmp)
       endif
   endif
   call mat_to_full(T2,1D0,T2full)
   phase1=kvec(1)*Aop%lvec(layer)%std_coord(1)
   phase2=kvec(2)*Aop%lvec(layer)%std_coord(2)
   phase3=kvec(3)*Aop%lvec(layer)%std_coord(3)
   phase=CMPLX(0.,(phase1+phase2+phase3),COMPLEXK)
   energy2_k=energy2_k+T2full*exp(phase)
ENDDO

call mat_free(T2_tmp)
call mat_free(T2)

END SUBROUTINE pbc_get_twop_matrix
END MODULE PBC_kspce_rspc_operations

