!> @file 
!> Contains essential matrix operations module and standalone BSM routines.

!> Contains wrapper routines that branch out to matrix routine for chosen matrix type.
!> \author L. Thogersen
!> \date 2003
!>
!> General rules:
!> NEVER put a type(Matrix) as intent(out), this will on some platforms
!>       make the pointer
!>       disassociated entering the routine, and memory already
!>       allocated for the matrix will be lost. \n
!> NEVER think that e.g. A%elms = matrix will copy the matrix elements from
!>       matrix to A%elms, it will only associate the pointer with the array
!>       matrix. \n
!> BUT type(Matrix) :: A,B; A = B SHOULD copy the matrix elements from matrix B to A 
!>     (see mat_assign). \n
!> ALWAYS and ONLY call mat_free on a matrix you have initialized with mat_init.
!>
MODULE matrix_operations
!FIXME: order routines alphabetically
!   use lstiming
   use matrix_module
!   Use matrix_operations_symm_dense
   use matrix_operations_dense
   use matrix_operations_scalapack
   use LSTIMING
#ifndef UNITTEST
   Use matrix_operations_sparse1
#endif
#ifdef VAR_LSMPI
   use lsmpi_type, only: MATRIXTY
#endif
   use matrix_operations_csr
!   Use matrix_operations_unres_symm_dense
   use matrix_operations_unres_dense
!   use matrix_operations_unres_sparse1

!FrameWork to write to memory - usefull for scalapack 
!and when disk space is limited
type matrixfiletype2
type(matrix) :: mat
type(matrixfiletype2),pointer :: matnext
end type matrixfiletype2

type matrixfiletype
character(len=80) :: filename
integer           :: iunit
type(matrixfiletype),pointer :: filenext
type(matrixfiletype2),pointer :: matrixliststart
type(matrixfiletype2),pointer :: matrixlistend
type(matrixfiletype2),pointer :: matrixcurrent
end type matrixfiletype

type matrixmembuf
type(matrixfiletype),pointer :: fileliststart
type(matrixfiletype),pointer :: filelistend
end type matrixmembuf

!> type to contain all Matrices written to memory
   type(matrixmembuf),save :: matmembuf
!> Matrices are symmetric and dense (not implemented)
   integer, parameter :: mtype_symm_dense = 1
!> Matrices are dense (default) 
   integer, parameter :: mtype_dense = 2
!> Matrices are block sparse (BSM)
   integer, parameter ::  mtype_sparse_block = 3
!> Matrices are compressed sparse row (CSR) sparse
   integer, parameter ::  mtype_sparse1 = 4
!> Matrices are dense and have both alpha and beta part (default for open shell)
   integer, parameter ::  mtype_unres_dense = 5
!> Matrices are CSR sparse and have both alpha and beta part (not implemented)
   integer, parameter ::  mtype_unres_sparse1 = 6
!> Matrices are compressed sparse row (CSR) 
   integer, parameter ::  mtype_csr = 7
!> Matrices are MPI memory distributed using scalapack
   integer, parameter ::  mtype_scalapack = 8
!*****************
!Possible matrix types - 
!(Exploiting symmetry when operating sparse matrices is probably a vaste of effort - 
!therefore these combinations are removed)
!******************
!mtype_dense, mtype_sparse1, mtype_sparse2
!mtype_cplx_dense, mtype_cplx_sparse1, mtype_cplx_sparse2
!mtype_unres_dense, mtype_unres_sparse1, mtype_unres_sparse2
!mtype_cplx_unres_dense, mtype_cplx_unres_sparse1, mtype_cplx_unres_sparse2
!mtype_symm_dense
!mtype_cplx_symm_dense
!mtype_unres_symm_dense
!mtype_cplx_unres_symm_dense

!> Counts the total number of matrix multiplications used throughout calculation
   integer, save      :: no_of_matmuls! = 0
!> Counts the number of matrices allocated, if requested
   integer, save      :: no_of_matrices! = 0 
!> Tracks the maximum number of allocated matrices throughout calculation, if requested
   integer, save      :: max_no_of_matrices! = 0
!> Start time for timing of matrix routines (only if requested)
   real(realk), save  :: mat_TSTR
!> End time for timing of matrix routines (only if requested)
   real(realk), save  :: mat_TEN
!> This is set to one of the mtype... variables to indicate chosen matrix type
   integer,save :: matrix_type ! = mtype_dense !default dense
!> True if timings for matrix operations are requested
   logical,save :: INFO_TIME_MAT! = .false. !default no timings
   logical,save :: INFO_memory! = .false. !default no memory printout
!> Overload: The '=' sign may be used to set two type(matrix) structures equal, i.e. A = B
!!$   INTERFACE ASSIGNMENT(=)
!!$      module procedure mat_assign
!!$   END INTERFACE

   contains
!*** is called from LSDALTON.f90
!> \brief Sets the global variables
!> \author T. Kjaergaard
!> \date 2011
     SUBROUTINE SET_MATRIX_DEFAULT()
       implicit none

       no_of_matmuls = 0
       no_of_matrices = 0 
       max_no_of_matrices = 0
       matrix_type = mtype_dense !default dense
       INFO_TIME_MAT = .false. !default no timings
       INFO_memory = .false. !default no memory printout  
     END SUBROUTINE SET_MATRIX_DEFAULT

!*** is called from config.f90
!> \brief Sets the global variable matrix_type that determines the matrix type
!> \author L. Thogersen
!> \date 2003
!> \param a Indicates the matrix type (see module documentation) 
     SUBROUTINE mat_select_type(a,lupri,nbast)
#ifdef VAR_LSMPI
       use infpar_module
       use lsmpi_type
#endif
       implicit none
       INTEGER, INTENT(IN) :: a,lupri
       INTEGER, OPTIONAL :: nbast
       integer :: nrow,ncol,tmpcol,tmprow,nproc,K
       if(matrix_type.EQ.mtype_unres_dense.AND.a.EQ.mtype_scalapack)then
          WRITE(6,*)'mat_select_type: FALLBACK WARNING'
          WRITE(6,*)'SCALAPACK type matrices is not implemented for unrestricted calculations'
          WRITE(6,*)'We therefore use the dense unrestricted type - which do not use memory distribution'
       else
          matrix_type = a
          select case(matrix_type)             
          case(mtype_symm_dense)
             WRITE(lupri,'(A)') 'Matrix type: mtype_symm_dense'
          case(mtype_dense)
             WRITE(lupri,'(A)') 'Matrix type: mtype_dense'
          case(mtype_sparse_block)
             WRITE(lupri,'(A)') 'Matrix type: mtype_sparse_block'
          case(mtype_sparse1)
             WRITE(lupri,'(A)') 'Matrix type: mtype_sparse1'
          case(mtype_unres_dense)
             WRITE(lupri,'(A)') 'Matrix type: mtype_unres_dense'
          case(mtype_unres_sparse1)
             WRITE(lupri,'(A)') 'Matrix type: mtype_unres_sparse1'
          case(mtype_csr)
             WRITE(lupri,'(A)') 'Matrix type: mtype_csr'
          case(mtype_scalapack)
             WRITE(lupri,'(A)') 'Matrix type: mtype_scalapack'
          case default
             call lsquit("Unknown type of matrix",-1)
          end select
#ifdef VAR_LSMPI
          IF (infpar%mynum.EQ.infpar%master) THEN
             call ls_mpibcast(MATRIXTY,infpar%master,MPI_COMM_LSDALTON)
             call lsmpi_set_matrix_type_master(a)
             if(matrix_type.EQ.mtype_scalapack)then
                IF(.NOT.present(nbast))then
                   call lsquit('scalapack error in mat_select_type',-1)
                ENDIF
                print*,'TYPE SCALAPACK HAVE BEEN SELECTED' 
                nproc = infpar%nodtot
                nrow = nproc
                ncol = 1
                K=1
                do 
                   K=K+1
                   IF(nproc.LE.K)EXIT
                   tmprow = nproc/K
                   tmpcol = K
                   IF(tmprow*tmpcol.EQ.nproc)THEN
                      IF(tmprow+tmpcol.LE.nrow+nrow)THEN
                         nrow = tmprow
                         ncol = tmpcol
                      ENDIF
                   ENDIF
                enddo
                print*,'nrow=',nrow,'ncol=',ncol,'nodtot=',infpar%nodtot
                print*,'call PDM_GRIDINIT(',nrow,',',ncol,')'
                CALL PDM_GRIDINIT(nrow,ncol,nbast)
                IF(infpar%mynum.EQ.infpar%master)then
                   WRITE(lupri,*)'Scalapack Grid initiation Block Size = ',BLOCK_SIZE
                   WRITE(lupri,*)'Scalapack Grid initiation nprow      = ',nrow
                   WRITE(lupri,*)'Scalapack Grid initiation npcol      = ',ncol
                endif
             endif
          ENDIF
#endif
       endif
     END SUBROUTINE mat_select_type

     SUBROUTINE mat_finalize()
#ifdef VAR_LSMPI
       use infpar_module
       use lsmpi_type
#endif
       implicit none
#ifdef VAR_LSMPI
       if(matrix_type.EQ.mtype_scalapack)then
          CALL PDM_GRIDEXIT
       endif
#endif
     END SUBROUTINE mat_finalize
!> \brief Pass info about e.g. logical unit number for LSDALTON.OUT to matrix module 
!> \author L. Thogersen
!> \date 2003
!> \param lu_info Logical unit number for LSDALTON.OUT
!> \param info_info True if various info from matrix module should be printed
!> \param mem_monitor True if number of allocated matrices should be monitored
      SUBROUTINE mat_pass_info(lu_info,info_info,mem_monitor)
         implicit none
         integer, intent(in) :: lu_info
         logical, intent(in) :: info_info, mem_monitor
         mat_lu   = lu_info
         mat_info = info_info
         mat_mem_monitor = mem_monitor
      END SUBROUTINE mat_pass_info
!> \brief If called, timings from matrix routines will be printed 
!> \author L. Thogersen
!> \date 2003
      SUBROUTINE mat_timings
         implicit none
         INFO_TIME_MAT = .true. 
      END SUBROUTINE mat_timings
!***
!> \brief Returns the number of matrix multiplications used so far 
!> \author S. Host
!> \date 2009
!> \param n Number of matrix muliplications
      SUBROUTINE mat_no_of_matmuls(n)
         implicit none
         INTEGER, INTENT(out) :: n
         n = no_of_matmuls
      END SUBROUTINE mat_no_of_matmuls
!> \brief Initialize a type(matrix)
!> \author L. Thogersen
!> \date 2003
!> \param a type(matrix) that should be initialized
!> \param nrow Number of rows for a
!> \param ncol Number of columns for a
      SUBROUTINE mat_init(a,nrow,ncol,complex)
         implicit none
         TYPE(Matrix), TARGET :: a 
         INTEGER, INTENT(IN)  :: nrow, ncol
         LOGICAL, INTENT(IN), OPTIONAL :: complex
         !if 'a' has init tag AND self pointer, it means that it is already initialized
         !and in its original location. Re-initializing would leak memory, so err
!         if (a%init_magic_tag.EQ.mat_init_magic_value &
!             & .and. associated(a%init_self_ptr,a)) THEN
!            print*,'associated(a%init_self_ptr,a)',associated(a%init_self_ptr,a)
!            print*,'a%init_magic_tag',a%init_magic_tag
!            print*,'mat_init_magic_value',mat_init_magic_value
!            print*,'a%init_magic_tag.EQ.mat_init_magic_value',a%init_magic_tag.EQ.mat_init_magic_value
!            call lsQUIT('Error in mat_init: matrix is already initialized',-1)
!         endif
         a%init_magic_tag = mat_init_magic_value
         a%init_self_ptr => a
         !process optional complex
         if (present(complex)) then
            if (complex .and. matrix_type.NE.mtype_dense) &
               & call lsQUIT('Error in mat_init: complex only implemented for matrix type dense',-1)
            a%complex = complex
         else
            a%complex = .false.
         endif
         !record this mat_init in statistics
         if (mat_mem_monitor) then
            no_of_matrices = no_of_matrices + 1
            !write(mat_lu,*) 'Init: matrices allocated:', no_of_matrices
            if (no_of_matrices > max_no_of_matrices) max_no_of_matrices = no_of_matrices
         endif
         nullify(A%elms)
         nullify(A%elmsb)
         if (info_memory) write(mat_lu,*) 'Before mat_init: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_init(a)
         case(mtype_dense)
             call mat_dense_init(a,nrow,ncol)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_init(a,nrow,ncol)
         case(mtype_sparse_block)
#ifdef HAVE_BSM
           CALL bsm_init(a,nrow,ncol)
           a%nrow = nrow
           a%ncol = ncol
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_init(a)
         case(mtype_unres_dense)
             call mat_unres_dense_init(a,nrow,ncol)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_init(a)
         case(mtype_csr)
             call mat_csr_init(a,nrow,ncol)            
         case(mtype_scalapack)
             call mat_scalapack_init(a,nrow,ncol)            
         case default
              call lsquit("mat_init not implemented for this type of matrix",-1)
         end select

         NULLIFY(a%iaux, a%raux)
         if (info_memory) write(mat_lu,*) 'After mat_init: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_init

!> \brief Free a type(matrix) that has been initialized with mat_init
!> \author L. Thogersen
!> \date 2003
!> \param a type(matrix) that should be freed
      SUBROUTINE mat_free(a)
         implicit none
         TYPE(Matrix), TARGET :: a 
         !to be free'ed, the matrix must be in the same location where it was init'ed.
         !If not, it is probably a duplicate (like 'a' in (/a,b,c/)), in which case
         !we may end up double-free'ing, so err
         if (.not.ASSOCIATED(a%init_self_ptr,a)) &
             & call lsQUIT('Error in mat_free: matrix moved or duplicated',-1)
         nullify(a%init_self_ptr)
         !look at magic tag to verify matrix is initialized, then clear tag
         if (a%init_magic_tag.NE.mat_init_magic_value) &
             & call lsQUIT('Error in mat_free: matrix was not initialized',-1)
         a%init_magic_tag = 0
         !record this mat_free in statistics
         if (mat_mem_monitor) then
            no_of_matrices = no_of_matrices - 1
            !write(mat_lu,*) 'Free: matrices allocated:', no_of_matrices
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_free: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_free(a)
         case(mtype_dense)
             call mat_dense_free(a)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_free(a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call bsm_free(a)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_free(a)
         case(mtype_unres_dense)
             call mat_unres_dense_free(a)
         case(mtype_csr)
             call mat_csr_free(a)
         case(mtype_scalapack)
             call mat_scalapack_free(a)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_free(a)
         case default
              call lsquit("mat_free not implemented for this type of matrix",-1)
         end select

      !free auxaliary data
      if (ASSOCIATED(a%iaux)) deallocate(a%iaux)
      if (ASSOCIATED(a%raux)) deallocate(a%raux)

      a%nrow = -1; a%ncol = -1
      if (info_memory) write(mat_lu,*) 'After mat_free: mem_allocated_global =', mem_allocated_global

      END SUBROUTINE mat_free

!> \brief Count allocated memory for type(matrix)
!> \author L. Thogersen
!> \date 2003
!> \param nsize Number of real(realk) elements that have been allocated
      SUBROUTINE stat_allocated_memory(nsize)
         implicit none
         integer, intent(in) :: nsize 
         integer(kind=long) :: nsize2 
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call symm_dense_stat_allocated_memory(nsize)
         case(mtype_dense)
            nsize2 = nsize
            call mem_allocated_mem_type_matrix(nsize2)
#ifndef UNITTEST
         case(mtype_sparse1)
             call sp1_stat_allocated_memory(nsize)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
!             call bsm_stat_allocated_memory(nsize)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_free(nsize)
         case(mtype_unres_dense)
             call unres_dens_stat_allocated_mem(nsize)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_stat_allocated_memory(nsize)
         case default
              call lsquit("stat_allocated_memory not implemented for this type of matrix",-1)
         end select

      END SUBROUTINE stat_allocated_memory

!> \brief Count deallocated memory for type(matrix)
!> \author L. Thogersen
!> \date 2003
!> \param nsize Number of real(realk) elements that have been deallocated
      SUBROUTINE stat_deallocated_memory(nsize)
         implicit none
         integer, intent(in) :: nsize 
         integer(kind=long) :: nsize2 
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call symm_dense_stat_deallocated_memory(nsize)
         case(mtype_dense)
!             call dens_stat_deallocated_memory(nsize)
            nsize2 = nsize
            call mem_deallocated_mem_type_matrix(nsize2)
#ifndef UNITTEST
         case(mtype_sparse1)
             call sp1_stat_deallocated_memory(nsize)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
!             call bsm_stat_deallocated_memory(nsize)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_free(nsize)
         case(mtype_unres_dense)
             call unres_dens_stat_deallocated_mem(nsize)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_stat_deallocated_memory(nsize)
         case default
              call lsquit("stat_deallocated_memory not implemented for this type of matrix",-1)
         end select

      END SUBROUTINE stat_deallocated_memory

!> \brief Convert a standard fortran matrix to a type(matrix) - USAGE DISCOURAGED!
!> \author L. Thogersen
!> \date 2003
!> \param afull Standard fortran matrix that should be converted (n x n)
!> \param alpha The output type(matrix) is multiplied by alpha
!> \param a The output type(matrix) ((2n x 2n) if unrestricted, (n x n) otherwise)
!> \param mat_label If the character label is present, sparsity will be printed if using block-sparse matrices
!> \param unres3 If present and true, mat_unres_dense_set_from_full3 will be called instead of mat_unres_dense_set_from_full
!>  
!> BE VERY CAREFUL WHEN USING mat_set_from_full AND mat_to_full!!!!!!
!> Usage of these routines should be avoided whenever possible, since
!> you have to hardcode an interface to make them work with unrestriced
!> matrices (see e.g. di_get_fock in dalton_interface.f90) This is because
!> usually, a and afull should have the same dimensions, but for unrestricted
!> a is (n x n) and afull is (2n x 2n). The exception is if
!> unres3 = true. In that case, both a and afull are (n x n), and both 
!> the alpha and beta parts of a will be set equal to the afull.
!> 
      SUBROUTINE mat_set_from_full(afull,alpha, a, mat_label,unres3)
         implicit none
         real(realk), INTENT(IN) :: afull(*)
         real(realk), intent(in) :: alpha
         TYPE(Matrix)            :: a  !output
         character(*), INTENT(IN), OPTIONAL :: mat_label
         logical,intent(in) , OPTIONAL :: unres3
         real(realk)             :: sparsity
         real(realk),pointer     :: full(:,:)
         call time_mat_operations1
         !write(mat_lu,*) "Usage of mat_set_from_full discouraged!!!"
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'Before mat_set_from_full: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_set_from_full(afull,alpha,a)
         case(mtype_dense)
             call mat_dense_set_from_full(afull,alpha,a)
         case(mtype_csr)
             call mat_csr_set_from_full(afull,alpha,a)
         case(mtype_scalapack)
            call mat_scalapack_set_from_full(afull,alpha,a)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_set_from_full(afull,alpha,a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            IF(ALPHA.NE. 1E0_realk)CALL DSCAL(a%nrow*a%ncol,ALPHA,afull,1)
            call bsm_free(a)
            CALL bsm_init_from_full(a,a%nrow,a%ncol,afull,sparsity)
            IF(ALPHA.NE. 1E0_realk)CALL DSCAL(a%nrow*a%ncol,1E0_realk/ALPHA,afull,1)
            if(PRESENT(mat_label))&
                 &write(2,&
                 &'("BSM ",A," full->sparse, sparsity:",F6.1," % nnz:",F9.0)')&
                 & mat_label, sparsity*100E0_realk, sparsity*a%nrow*a%ncol
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_set_from_full(afull,alpha,a)
         case(mtype_unres_dense)
            if(PRESENT(unres3))then
               if(unres3)then
                  call mat_unres_dense_set_from_full3(afull,alpha,a)
               else
                  call mat_unres_dense_set_from_full(afull,alpha,a)
               endif
            else
               call mat_unres_dense_set_from_full(afull,alpha,a)
            endif
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_set_from_full(afull,alpha,a)
         case default
              call lsquit("mat_set_from_full not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_set_from_full: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('F_FULL',mat_TSTR,mat_TEN,mat_lu)
         call time_mat_operations2(JOB_mat_set_from_full)

      END SUBROUTINE mat_set_from_full

!> \brief Convert a type(matrix) to a standard fortran matrix - USAGE DISCOURAGED!
!> \author L. Thogersen
!> \date 2003
!> \param a The type(matrix) that should be converted (n x n)
!> \param afull The output standard fortran matrix ((2n x 2n) if unrestricted, (n x n) otherwise)
!> \param alpha The output standard fortran matrix is multiplied by alpha
!> \param mat_label If the character label is present, sparsity will be printed if using block-sparse matrices
!>  
!> BE VERY CAREFUL WHEN USING mat_set_from_full AND mat_to_full!!!!!!
!> Usage of these routines should be avoided whenever possible, since
!> you have to hardcode an interface to make them work with unrestriced
!> matrices (see e.g. di_get_fock in dalton_interface.f90)
!>
     SUBROUTINE mat_to_full(a, alpha, afull,mat_label)

         implicit none
         TYPE(Matrix), intent(in):: a
         real(realk), intent(in) :: alpha
         real(realk), intent(inout):: afull(*)  !output
         character(*), INTENT(IN), OPTIONAL :: mat_label
         real(realk)             :: sparsity
         call time_mat_operations1

         !write(mat_lu,*) "Usage of mat_to_full discouraged!!!"
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         !if (SIZE(afull) < a%nrow*a%ncol) then
         !  call lsquit('too small full array in mat_to_full',-1)
         !endif
         if (info_memory) write(mat_lu,*) 'Before mat_to_full: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_to_full(a, alpha, afull)
         case(mtype_dense)
             call mat_dense_to_full(a, alpha, afull)
         case(mtype_csr)
             call mat_csr_to_full(a, alpha, afull)
         case(mtype_scalapack)
            call mat_scalapack_to_full(a, alpha, afull)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_to_full(a, alpha, afull)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            call bsm_to_full(a, afull, sparsity)
            if(ALPHA.NE. 1E0_realk)CALL DSCAL(a%nrow*a%ncol, alpha, afull, 1)
            if(PRESENT(mat_label))&
                 &write(2,&
                 &'("BSM ",A," sparse->full, sparsity:",F6.1," % nnz:",F9.0)')&
                 & mat_label, sparsity*100E0_realk, sparsity*a%nrow*a%ncol
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_to_full(a, alpha, afull)
         case(mtype_unres_dense)
             call mat_unres_dense_to_full(a, alpha, afull)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_to_full(a, alpha, afull)
         case default
              call lsquit("mat_to_full not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('TOFULL',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_to_full: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_to_full)
      END SUBROUTINE mat_to_full

!> \brief Print a type(matrix) to file in pretty format
!> \author L. Thogersen
!> \date 2003
!> \param a The type(matrix) that should be printed
!> \param i_row1 Print starting from this row
!> \param i_rown Print ending at this row
!> \param j_col1 Print starting from this column
!> \param j_coln Print ending at this column
!> \param lu Print to file with this logical unit number
      SUBROUTINE mat_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         implicit none
         TYPE(Matrix),intent(in) :: a
         integer, intent(in)     :: i_row1, i_rown, j_col1, j_coln, lu 
         REAL(REALK), ALLOCATABLE :: afull(:,:)
         real(realk)              :: sparsity

         if (i_row1 < 1 .or. j_col1 < 1 .or. a%nrow < i_rown .or. a%ncol < j_coln) then
           CALL LSQUIT( 'subsection out of bounds in mat_print',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_print: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         case(mtype_dense)
             call mat_dense_print(a, i_row1, i_rown, j_col1, j_coln, lu)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         case(mtype_scalapack)
            print*,'FALLBACK scalapack print'
            ALLOCATE (afull(a%nrow,a%ncol))
#ifdef VAR_SCALAPACK
            call mat_scalapack_to_full(a, 1E0_realk,afull)
            CALL OUTPUT(afull, i_row1, i_rown, j_col1, j_coln,A%nrow,A%ncol,1, lu)
#endif
            DEALLOCATE(afull)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            ALLOCATE (afull(a%nrow,a%ncol))
            call bsm_to_full(a, afull,sparsity)
            CALL OUTPUT(afull, i_row1, i_rown, j_col1, j_coln,A%nrow,A%ncol,1, lu)
            DEALLOCATE(afull)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         case(mtype_unres_dense)
             call mat_unres_dense_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         case(mtype_csr)
             call mat_csr_print(a, lu)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_print(a, i_row1, i_rown, j_col1, j_coln, lu)
         case default
              call lsquit("mat_print not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_print: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_print

!> \brief Transpose a type(matrix).
!> \author L. Thogersen
!> \date 2003
!> \param a The type(matrix) that should be transposed
!> \param b The transposed output type(matrix).
!>
!> Usage discouraged! If what you want is to multiply your transposed
!> matrix with something else, you should instead use mat_mul with the
!> transpose flag 'T'. This is much more efficient than transposing first 
!> and then multiplying.
!>
      SUBROUTINE mat_trans(a, b) !USAGE DISCOURAGED!!
         implicit none
         TYPE(Matrix),intent(in)     :: a
         TYPE(Matrix)                :: b !output
         REAL(REALK), ALLOCATABLE :: afull(:,:)
         call time_mat_operations1
                  
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (b%nrow /= a%ncol .or. b%ncol /= a%nrow) then
           CALL LSQUIT( 'wrong dimensions in mat_trans',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_trans: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_trans(a,b)
         case(mtype_dense)
             call mat_dense_trans(a,b)
         case(mtype_csr)
             call mat_csr_trans(a,b)
         case(mtype_scalapack)
             call mat_scalapack_trans(a,b)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_trans(a,b)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
#if 0
            real(realk) :: sparsity
            ALLOCATE (afull(a%nrow,a%ncol))
            call bsm_to_full(a, afull,sparsity)
            afull = transpose(afull)
            call bsm_free(b)
            CALL bsm_init_from_full(b,a%nrow,a%ncol,afull,sparsity)
            DEALLOCATE(afull)
#else
            call bsm_transpose(a, b)
#endif
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_trans(a,b)
         case(mtype_unres_dense)
             call mat_unres_dense_trans(a,b)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_trans(a,b)
         case default
              call lsquit("mat_trans not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('TRANS ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_trans)

      END SUBROUTINE mat_trans

!> \brief Compute the Cholesky decomposition factors of a positive definite matrix
!> \author T. Kjærgaard
!> \date 2012
!> \param a The type(matrix) that should be decomposed
!> \param b The output type(matrix) that contains the cholesky factors.
      SUBROUTINE mat_chol(a, b) 
        implicit none
        TYPE(Matrix),intent(in)     :: a
        TYPE(Matrix),intent(inout)  :: b !output
        real(realk), pointer   :: work1(:)
        real(realk), pointer   :: U_full(:,:)
        integer,pointer    :: IPVT(:)
        real(realk)            :: RCOND, dummy(2), tmstart, tmend
        integer                :: IERR, i, j, fulldim, ndim
        call time_mat_operations1
        if (b%nrow /= a%ncol .or. b%ncol /= a%nrow) then
           CALL LSQUIT( 'wrong dimensions in mat_trans',-1)
        endif
        if (info_memory) write(mat_lu,*) 'Before mat_inv: mem_allocated_global =', mem_allocated_global
        select case(matrix_type)
        case(mtype_unres_dense)
           fulldim = 2*a%nrow
        case(mtype_dense)
           fulldim = a%nrow
        case default
           fulldim = a%nrow
        end select

        select case(matrix_type)
!        case(mtype_dense)
!           call mat_dense_chol(a,b)
!        case(mtype_scalapack)
!           call mat_scalapack_chol(a,b)
!         case(mtype_unres_dense)
!             call mat_unres_dense_inv(a,b)
        case default
           call mem_alloc(U_full,fulldim,fulldim) 
           call mem_alloc(work1,fulldim)
           call mem_alloc(IPVT,fulldim)
           call mat_to_full(A,1.0E0_realk,U_full)
           !Set lower half of U = 0:
           do i = 1, fulldim
              do j = 1, i-1
                 U_full(i,j) = 0.0E0_realk
              enddo
           enddo           
           call dchdc(U_full,fulldim,fulldim,work1,0,0,IERR)           
           call mat_set_from_full(U_full,1.0E0_realk,B)
           call mem_dealloc(U_full) 
           call mem_dealloc(work1)
           call mem_dealloc(IPVT)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_chol)
       END SUBROUTINE mat_chol

!> \brief Compute the Cholesky decomposition factors of a positive definite matrix
!> \author T. Kjærgaard
!> \date 2012
!> \param a The type(matrix) that should be decomposed
      SUBROUTINE mat_dpotrf(a) 
        implicit none
        TYPE(Matrix),intent(inout)     :: a !overwrites matrix A
        integer :: info
!        call time_mat_operations1
        if (info_memory) write(mat_lu,*) 'Before mat_inv: mem_allocated_global =', mem_allocated_global
        select case(matrix_type)
        case(mtype_dense)
           INFO = 0
           CALL DPOTRF('U',A%nrow,A%elms,A%nrow,INFO)
           IF(INFO.NE.0)CALL LSQUIT('DPOTRF ERROR',-1)
        case(mtype_scalapack)
           call mat_scalapack_dpotrf(a)
        case(mtype_unres_dense)
           INFO = 0
           CALL DPOTRF('U',A%nrow,A%elms,A%nrow,INFO)
           IF(INFO.NE.0)CALL LSQUIT('DPOTRF ERROR',-1)
           INFO = 0
           CALL DPOTRF('U',A%nrow,A%elmsb,A%nrow,INFO)
           IF(INFO.NE.0)CALL LSQUIT('DPOTRF ERROR',-1)
        case default
           call lsquit("mat_dpotrf not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
!         call time_mat_operations2(JOB_mat_dpotrf)
       END SUBROUTINE mat_dpotrf

!> \brief Solve the system A*X = B overwriting B with X
!> \author T. Kjærgaard
!> \date 2012
!> \param a The type(matrix) that contain cholesky factors from mat_dpotrf
!> \param b input B output X 
     SUBROUTINE mat_dpotrs(A,B) 
        implicit none
        TYPE(Matrix),intent(in)        :: a
        TYPE(Matrix),intent(inout)     :: b
        integer :: INFO
!        call time_mat_operations1
        if (info_memory) write(mat_lu,*) 'Before mat_inv: mem_allocated_global =', mem_allocated_global
        select case(matrix_type)
        case(mtype_dense)
           CALL DPOTRS('U',A%nrow,B%ncol,A%elms,A%nrow,B%elms,B%nrow,INFO)
        case(mtype_scalapack)
           call mat_scalapack_dpotrs(a,b)
        case(mtype_unres_dense)
           CALL DPOTRS('U',A%nrow,B%ncol,A%elms,A%nrow,B%elms,B%nrow,INFO)
           CALL DPOTRS('U',A%nrow,B%ncol,A%elmsb,A%nrow,B%elmsb,B%nrow,INFO)
        case default
           call lsquit("mat_dpotrf not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
!         call time_mat_operations2(JOB_mat_dpotrs)
       END SUBROUTINE mat_dpotrs

!> \brief compute the inverse matrix of real sym positive definite matrix A
!> \author T. Kjærgaard
!> \date 2012
!> \param a The type(matrix) that contain cholesky factors from mat_dpotrf
!> on entry the A matrix is the cholesky factors from mat_dpotrf on exit
!> is the upper triangluar matrix of the symmetric inverse of A 
     SUBROUTINE mat_dpotri(A) 
        implicit none
        TYPE(Matrix),intent(inout)        :: a
        integer :: INFO
!        call time_mat_operations1
        if (info_memory) write(mat_lu,*) 'Before mat_inv: mem_allocated_global =', mem_allocated_global
        select case(matrix_type)
        case(mtype_dense)
           CALL DPOTRI('U',A%nrow,A%elms,A%nrow,INFO)           
           IF(INFO.NE.0)CALL LSQUIT('DPOTRI ERROR',-1)
           !note that depending how you use this you will need to copy the  
!        case(mtype_scalapack)
           !           call mat_scalapack_chol(a,b)
        case(mtype_unres_dense)
           CALL DPOTRI('U',A%nrow,A%elms,A%nrow,INFO)           
           IF(INFO.NE.0)CALL LSQUIT('DPOTRI ERROR',-1)
           CALL DPOTRI('U',A%nrow,A%elmsb,A%nrow,INFO)           
           IF(INFO.NE.0)CALL LSQUIT('DPOTRI ERROR',-1)
        case default
           call lsquit("mat_dpotrf not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
!         call time_mat_operations2(JOB_mat_dpotri)
       END SUBROUTINE mat_dpotri

!> \brief creates the inverse matrix of type(matrix).
!> \author T. Kjærgaard
!> \date 2012
!> \param a The type(matrix) that should be inversed
!> \param chol The type(matrix) that contains cholesky factors (from mat_chol)
!> \param c The inverse output type(matrix).
      SUBROUTINE mat_inv(A, A_inv) 
         implicit none
         TYPE(Matrix),intent(in)     :: A
         TYPE(Matrix)                :: A_inv !output
         real(realk), pointer   :: work1(:)
         real(realk), pointer   :: A_inv_full(:,:) 
         integer,pointer    :: IPVT(:)
         real(realk)            :: RCOND, dummy(2), tmstart, tmend
         integer                :: IERR, i, j, fulldim, ndim

         call time_mat_operations1
                  
        select case(matrix_type)
        case(mtype_unres_dense)
           fulldim = 2*a%nrow
        case(mtype_dense)
           fulldim = a%nrow
        case default
           fulldim = a%nrow
        end select

         if (info_memory) write(mat_lu,*) 'Before mat_inv: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_dense)
!             call mat_dense_inv(a,b)
!         case(mtype_scalapack)
!             call mat_scalapack_inv(a,b)
!         case(mtype_unres_dense)
!             call mat_unres_dense_inv(a,b)
         case default
            call mem_alloc(A_inv_full,fulldim,fulldim) 
            call mem_alloc(work1,fulldim)
            call mem_alloc(IPVT,fulldim)
            !Invert U and Ut:
            IPVT = 0 ; RCOND = 0.0E0_realk  
            call mat_to_full(A,1.0E0_realk,A_inv_full)
            call DGECO(A_inv_full,fulldim,fulldim,IPVT,RCOND,work1)
            call DGEDI(A_inv_full,fulldim,fulldim,IPVT,dummy,work1,01)
            !Convert framework:
            call mat_set_from_full(A_inv_full,1.0E0_realk,A_inv)
            call mem_dealloc(A_inv_full) 
            call mem_dealloc(work1)
            call mem_dealloc(IPVT)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_trans: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_inv)

      END SUBROUTINE mat_inv

!> \brief Clone a type(matrix).
!> \author B. Jansik
!> \date 2009
!> \param dest The destination type(matrix) 
!> \param src The source type(matrix) that should be cloned.
!>
!> This makes clone of matrix src to dest, similar to mat_assign, except that it is still in same
!> memory. Matrix src can then be accessed also by the dest name. All of this could be much easier, just dest=src;
!> if not for that bloody '=' operator overload with mat_assign!!
!> 
      SUBROUTINE mat_clone(dest,src)
      implicit none
      type(Matrix) :: src, dest
            dest%ncol=src%ncol; dest%nrow=src%nrow
            dest%elms=>src%elms; dest%idata=>src%idata
            dest%permutation => src%permutation
            dest%elmsb=>src%elmsb; dest%celms=>src%celms
            dest%celmsb=>src%celmsb; dest%selm1=>src%selm1
            dest%block => src%block; dest%blockpos=>src%blockpos
            dest%iaux => src%iaux; dest%raux => src%raux
            dest%complex = src%complex
            dest%val => src%val; dest%col => src%col
            dest%row => src%row; dest%nnz = src%nnz
#ifdef VAR_SCALAPACK
            dest%localncol=src%localncol; dest%localnrow=src%localnrow
            dest%addr_on_grid => src%addr_on_grid
            dest%p => src%p
#endif
      END SUBROUTINE mat_clone
   
!> \brief Copy a type(matrix).
!> \author L. Thogersen
!> \date 2003
!> \param a The copy output type(matrix)
!> \param b The type(matrix) that should be copied.
      SUBROUTINE mat_assign(a, b)
         implicit none
         TYPE(Matrix), INTENT(INOUT) :: a
         TYPE(Matrix), INTENT(IN)    :: b
         call time_mat_operations1
         
         if (a%nrow /= b%nrow .or. a%ncol /= b%ncol) then
            call lsquit('wrong dimensions in mat_assign',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_assign: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_assign(a,b)
         case(mtype_dense)
             call mat_dense_assign(a,b)
          case(mtype_csr)
             call mat_csr_assign(a,b)
          case(mtype_scalapack)
             call mat_scalapack_assign(a,b)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_assign(a,b)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call bsm_assign(a,b)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_assign(a,b)
         case(mtype_unres_dense)
             call mat_unres_dense_assign(a,b)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_assign(a,b)
         case default
              call lsquit("mat_assign not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_assign: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_assign)

       END SUBROUTINE mat_assign

#ifndef UNITTEST
!> \brief MPI broadcast a type(matrix).
!> \author T. Kjaergaard
!> \date 2010
!> \param a The type(matrix) that should be copied
!> \param slave , true if slave process 
!> \param master integer of master process
      SUBROUTINE mat_mpicopy(a, slave, master)
         implicit none
         TYPE(Matrix), INTENT(INOUT) :: a
         integer(kind=ls_mpik),intent(in) :: master 
         logical,intent(in) :: slave

         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_mpicopy(a,slave, master)
         case(mtype_scalapack)
            call lsquit('mat_mpicopy scalapack error',-1)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_mpicopy(a,slave, master)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call mat_bsm_mpicopy_fallback(a,slave, master)
#endif
#endif
         case(mtype_unres_dense)
             call mat_unres_dense_mpicopy(a,slave, master)
         case default
              call lsquit("mpicopy_typematrix not implemented for this type of matrix",-1)
         end select
       contains
         subroutine mat_bsm_mpicopy_fallback(A,slave,master)
           use lsmpi_type
          implicit none
          type(Matrix), intent(inout) :: A
          logical                     :: slave
          integer(kind=ls_mpik)       :: master
          
          real(realk), allocatable :: Afull(:,:)
          integer                  :: i, j
          
          CALL LS_MPI_BUFFER(A%nrow,Master)
          CALL LS_MPI_BUFFER(A%ncol,Master)
          allocate(Afull(A%nrow,A%ncol))
          IF(.NOT.SLAVE)call mat_to_full(A,1.0E0_realk,Afull)
          CALL LS_MPI_BUFFER(Afull,A%nrow,A%ncol,Master)
          
          IF(SLAVE)THEN
             call mat_init(A,A%nrow,A%ncol)
             call mat_set_from_full(Afull,1.0E0_realk,A) 
          ENDIF
          deallocate(Afull)
          
         end subroutine mat_bsm_mpicopy_fallback
       END SUBROUTINE mat_mpicopy
#endif

!> \brief Copy and scale a type(matrix).
!> \author L. Thogersen
!> \date 2003
!> \param alpha The scaling parameter
!> \param a The type(matrix) that should be copied
!> \param b The scaled output type(matrix).
      SUBROUTINE mat_copy(alpha,a, b) ! USAGE DISCOURAGED!
         implicit none
         REAL(REALK),  INTENT(IN)    :: alpha
         TYPE(Matrix), INTENT(IN)    :: a
         TYPE(Matrix), INTENT(INOUT) :: b
         call time_mat_operations1
         
         if (b%nrow /= a%nrow .or. b%ncol /= a%ncol) then
           CALL LSQUIT( 'wrong dimensions in mat_copy',-1)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_copy(alpha,a,b)
         case(mtype_dense)
             call mat_dense_copy(alpha,a,b)
         case(mtype_csr)
             call mat_csr_copy(alpha,a,b)
         case(mtype_scalapack)
             call mat_scalapack_copy(alpha,a,b)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_copy(alpha,a,b)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call bsm_copy(alpha,a,b)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_copy(alpha,a,b)
         case(mtype_unres_dense)
             call mat_unres_dense_copy(alpha,a,b)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_copy(alpha,a,b)
         case default
              call lsquit("mat_copy not implemented for this type of matrix",-1)
         end select
         call time_mat_operations2(JOB_mat_copy)

      END SUBROUTINE mat_copy

!> \brief Makes the trace of a square type(matrix).
!> \param a The type(matrix) we want the trace of
!> \return The trace of a
!> \author L. Thogersen
!> \date 2003
      FUNCTION mat_tr(a)
         implicit none
         TYPE(Matrix), intent(IN) :: a
         REAL(realk) :: mat_tr
#ifdef HAVE_BSM
         REAL(realk), EXTERNAL :: bsm_tr
#endif
         call time_mat_operations1

         if (a%nrow /= a%ncol) then
           print *, 'a%nrow, a%ncol =', a%nrow, a%ncol
           CALL LSQUIT( 'Trace is only defined for a square matrix!',-1)
         endif
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'Before mat_tr: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             mat_Tr = mat_symm_dense_Tr(a)
         case(mtype_dense)
             mat_Tr = mat_dense_Tr(a)
         case(mtype_csr)
            mat_tr = mat_csr_Tr(a)
         case(mtype_scalapack)
            mat_tr = mat_scalapack_Tr(a)
#ifndef UNITTEST
         case(mtype_sparse1)
             mat_Tr = mat_sparse1_Tr(a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             mat_Tr = bsm_tr(a)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             mat_Tr = mat_unres_symm_dense_Tr(a)
         case(mtype_unres_dense)
             mat_Tr = mat_unres_dense_Tr(a)
!         case(mtype_unres_sparse1)
!             mat_Tr = mat_unres_sparse1_Tr(a)
         case default
              call lsquit("mat_Tr not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('TRACE ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_tr: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_tr)

      END FUNCTION mat_tr

!> \brief Make the trace of the product of type(matrix) A and B.
!> \author L. Thogersen
!> \date 2003
!> \param a The first type(matrix) factor
!> \param b The second type(matrix) factor
!> \return Tr(a*b)
      FUNCTION mat_trAB(a,b)
         implicit none
         TYPE(Matrix), intent(IN) :: a,b
         REAL(realk) :: mat_trAB
#ifdef HAVE_BSM
         REAL(realk), EXTERNAL :: bsm_trAB
#endif
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (a%ncol /= b%nrow .or. a%nrow /= b%ncol) then
           CALL LSQUIT( 'wrong dimensions in mat_trAB',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_trAB: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             mat_TrAB = mat_symm_dense_TrAB(a,b)
         case(mtype_dense)
             mat_TrAB = mat_dense_TrAB(a,b)
         case(mtype_csr)
             mat_TrAB = mat_csr_TrAB(a,b)
         case(mtype_scalapack)
             mat_TrAB = mat_scalapack_TrAB(a,b)
#ifndef UNITTEST
         case(mtype_sparse1)
             mat_TrAB = mat_sparse1_TrAB(a,b)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             mat_TrAB = bsm_trAB(a,b)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             mat_TrAB = mat_unres_symm_dense_TrAB(a,b)
         case(mtype_unres_dense)
             mat_TrAB = mat_unres_dense_TrAB(a,b)
!         case(mtype_unres_sparse1)
!             mat_TrAB = mat_unres_sparse1_TrAB(a,b)
         case default
              call lsquit("mat_TrAB not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('TR_AB ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_trAB: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_trAB)

      END FUNCTION mat_trAB

!=======================================================================

!> \brief Make c = alpha*ab + beta*c, where a,b,c are type(matrix) and alpha,beta are parameters
!> \author L. Thogersen
!> \date 2003
!> \param a The first type(matrix) factor
!> \param b The second type(matrix) factor
!> \param transa 'T'/'t' if a should be transposed, 'N'/'n' otherwise
!> \param transb 'T'/'t' if b should be transposed, 'N'/'n' otherwise
!> \param alpha The alpha parameter
!> \param beta The beta parameter
!> \param c The output type(matrix)
      SUBROUTINE mat_mul(a, b, transa, transb, alpha, beta, c)
         !c = alpha*ab + beta*c
         !transa = 'T'/'t' - transposed, 'N'/'n' - normal
         implicit none
         TYPE(Matrix), intent(IN) :: a, b
         character, intent(in)    :: transa, transb
         REAL(realk), INTENT(IN)  :: alpha, beta
         TYPE(Matrix), intent(inout):: c
         integer :: ak, bk, ci, cj
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         no_of_matmuls = no_of_matmuls + 1
         if (transa == 'n' .or. transa == 'N') then
           ak = a%ncol
           ci = a%nrow
         elseif (transa == 't' .or. transa == 'T') then
           ak = a%nrow
           ci = a%ncol
         endif
         if (transb == 'n' .or. transb == 'N') then
           bk = b%nrow
           cj = b%ncol
         elseif (transb == 't' .or. transb == 'T') then
           bk = b%ncol
           cj = b%nrow
         endif
         if (ak /= bk .or. ci /= c%nrow .or. cj /= c%ncol) then
           print*,'ak',ak,'bk',bk,'ci',ci,'cj',cj
           Call lsquit('wrong dimensions in mat_mul or unknown trans possibility',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_mul: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_mul(a,b,transa, transb,alpha,beta,c)
         case(mtype_dense)
            call mat_dense_mul(a,b,transa, transb,alpha,beta,c)
#ifndef UNITTEST
         case(mtype_sparse1)
            call mat_sparse1_mul(a,b,transa, transb,alpha,beta,c)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call bsm_mul(a,b,transa, transb,alpha,beta,c)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_mul(a,b,transa, transb,alpha,beta,c)
         case(mtype_unres_dense)
             call mat_unres_dense_mul(a,b,transa, transb,alpha,beta,c)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_mul(a,b,transa, transb,alpha,beta,c)
         case(mtype_csr)
             call mat_csr_mul(a,b,transa, transb,alpha,beta,c)
         case(mtype_scalapack)
             call mat_scalapack_mul(a,b,transa, transb,alpha,beta,c)
         case default
              call lsquit("mat_mul not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('MATMUL ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_mul: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_mul)

      END SUBROUTINE mat_mul

!> \brief Make c = alpha*a + beta*b, where a,b are type(matrix) and alpha,beta are parameters
!> \author L. Thogersen
!> \date 2003
!> \param a The first type(matrix) 
!> \param alpha The alpha parameter
!> \param b The second type(matrix) 
!> \param beta The beta parameter
!> \param c The output type(matrix)
      SUBROUTINE mat_add(alpha, a, beta, b, c)
         implicit none
         TYPE(Matrix), intent(IN) :: a, b
         REAL(realk), INTENT(IN)  :: alpha, beta
         TYPE(Matrix)             :: c
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (a%nrow /= b%nrow .or. a%ncol /= b%ncol .or. a%nrow /= c%nrow &
            &.or. a%ncol /= c%ncol) then
           print *, 'a%nrow, a%ncol, b%nrow, b%ncol, c%nrow, c%ncol', a%nrow, a%ncol, b%nrow, b%ncol, c%nrow, c%ncol
           CALL LSQUIT( 'wrong dimensions in mat_add',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_add: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_add(alpha,a,beta,b,c)
         case(mtype_dense)
             call mat_dense_add(alpha,a,beta,b,c)
#ifndef UNITTEST
         case(mtype_csr)
             call mat_csr_add(alpha,a,beta,b,c)
         case(mtype_scalapack)
             call mat_scalapack_add(alpha,a,beta,b,c)
         case(mtype_sparse1)
             call mat_sparse1_add(alpha,a,beta,b,c)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             call bsm_add(alpha,a,beta,b,c)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_add(alpha,a,beta,b,c)
         case(mtype_unres_dense)
             call mat_unres_dense_add(alpha,a,beta,b,c)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_add(alpha,a,beta,b,c)
         case default
              call lsquit("mat_add not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('ADD   ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_add: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_add)

      END SUBROUTINE mat_add

!> \brief Make Y = alpha*X + Y where X,Y are type(matrix) and a is a parameter
!> \author L. Thogersen
!> \date 2003
!> \param alpha The alpha parameter
!> \param X The input type(matrix) 
!> \param Y The input/output type(matrix) 
      SUBROUTINE mat_daxpy(alpha, X, Y)
         implicit none
         real(realk),intent(in)       :: alpha
         TYPE(Matrix), intent(IN)     :: X
         TYPE(Matrix), intent(INOUT)  :: Y
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (x%nrow /= y%nrow .or. x%ncol /= y%ncol) then
            call lsquit('wrong dimensions in mat_daxpy',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_daxpy: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_daxpy(alpha,X,y)
         case(mtype_dense)
             call mat_dense_daxpy(alpha,x,y)
         case(mtype_csr)
             call mat_csr_daxpy(alpha,x,y)
         case(mtype_scalapack)
             call mat_scalapack_daxpy(alpha,x,y)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_daxpy(alpha,x,y)
#ifdef HAVE_BSM
          case(mtype_sparse_block)
             call bsm_daxpy(alpha,x,y)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_daxpy(alpha,x,y)
         case(mtype_unres_dense)
             call mat_unres_dense_daxpy(alpha,x,y)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_daxpy(alpha,x,y)
         case default
              call lsquit("mat_daxpy not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('DAXPY ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_daxpy: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_daxpy)

      END SUBROUTINE mat_daxpy

!> \brief solves Ax=b where A,x,b are type(matrix) 
!> \author J. Rekkedal
!> \date 2003
!> \param alpha The alpha parameter
!> \param A The input type(matrix) 
!> \param x The input/output type(matrix) 
!> \param b The input type(matrix) 
      SUBROUTINE mat_dposv(A,b,lupri)
         implicit none
         TYPE(Matrix), intent(INOUT)  :: A
         TYPE(Matrix), intent(INOUT)  :: b
         INTEGER,INTENT(IN)           :: lupri

         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_dposv(A,b,lupri)
         case default
              call lsquit("mat_dposv not implemented for this type of matrix",-1)
         end select

      END SUBROUTINE mat_dposv

      SUBROUTINE mat_dense_dposv(A,b,lupri)
         implicit none
         TYPE(Matrix), intent(INOUT)  :: A
         TYPE(Matrix), intent(INOUT)  :: b
         INTEGER,INTENT(IN)           :: lupri
         Real(Realk),pointer          :: Af(:,:)
         Real(Realk),pointer          :: bf(:,:)
         INTEGER                      :: dim1,dim2,dim3,dim4
         INTEGER                      :: info

         dim1=A%nrow
         dim2=A%ncol
         dim3=b%nrow
         dim4=b%ncol
         if(dim3 .ne. A%nrow) then
           call lsquit('mat_dense_dposv, Reason: Wrong dim3',lupri)
         endif
         call mem_alloc(Af,dim1,dim2)
         call mem_alloc(bf,dim3,dim4)
         call mat_to_full(A,1D0,Af)
         call mat_to_full(b,1D0,bf)

         call dposv('U',dim1,dim4,Af,dim1,bf,dim3,info)

         if(info .ne. 0) then
           call lsquit('mat_dense_dposv, Reason: info not 0',lupri)
         endif

         call mat_set_from_full(Af,1D0,A)
         call mat_set_from_full(bf,1D0,b)
         call mem_dealloc(Af)
         call mem_dealloc(bf)

      END SUBROUTINE mat_dense_dposv

!> \brief Make the dot product of type(matrix) a and b.
!> \author L. Thogersen
!> \date 2003
!> \param a The first type(matrix) factor
!> \param b The second type(matrix) factor
!> \return The dot product of a and b
      function mat_dotproduct(a,b)
         implicit none
         TYPE(Matrix), intent(IN) :: a,b
         REAL(realk) :: mat_dotproduct
#ifdef HAVE_BSM
         REAL(realk), EXTERNAL :: bsm_trAtransB
#endif
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (a%nrow*a%ncol /= b%nrow*b%ncol) then
           CALL LSQUIT( 'wrong dimensions in mat_dotproduct',-1)
         endif
         if (info_memory) write(mat_lu,*) 'Before mat_dotproduct: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             mat_dotproduct = mat_symm_dense_dotproduct(a,b)
         case(mtype_dense)
            mat_dotproduct = mat_dense_dotproduct(a,b)
         case(mtype_csr)
            mat_dotproduct = mat_csr_dotproduct(a,b)
         case(mtype_scalapack)
            mat_dotproduct = mat_scalapack_dotproduct(a,b)
#ifndef UNITTEST
         case(mtype_sparse1)
             mat_dotproduct = mat_sparse1_dotproduct(a,b)
#ifdef HAVE_BSM
          case(mtype_sparse_block)
             mat_dotproduct = bsm_trAtransB(a,b)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             mat_dotproduct = mat_unres_symm_dense_dotproduct(a,b)
         case(mtype_unres_dense)
             mat_dotproduct = mat_unres_dense_dotproduct(a,b)
!         case(mtype_unres_sparse1)
!             mat_dotproduct = mat_unres_sparse1_dotproduct(a,b)
         case default
              call lsquit("mat_dotproduct not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('DOTPRO',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_dotproduct: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_dotproduct)

      END FUNCTION mat_dotproduct

!> \brief Make the dot product of type(matrix) a with itself.
!> \author L. Thogersen
!> \date 2003
!> \param a The type(matrix) input
!> \return The dot product of a with itself
      FUNCTION mat_sqnorm2(a)
         implicit none
         TYPE(Matrix), intent(IN) :: a
         REAL(realk) :: mat_sqnorm2
#ifdef HAVE_BSM
         REAL(realk), external:: bsm_frob
#endif
         call time_mat_operations1

         if (info_memory) write(mat_lu,*) 'Before mat_sqnorm2: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
            !         case(mtype_symm_dense)
            !             mat_sqnorm2 = mat_symm_dense_sqnorm2(a)
         case(mtype_dense)
            mat_sqnorm2 = mat_dense_sqnorm2(a)
         case(mtype_csr)
            mat_sqnorm2 = mat_csr_sqnorm2(a)
         case(mtype_scalapack)
            mat_sqnorm2 = mat_scalapack_sqnorm2(a)
#ifndef UNITTEST
         case(mtype_sparse1)
            mat_sqnorm2 = mat_sparse1_sqnorm2(a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            mat_sqnorm2 = bsm_frob(a)**2
#endif
#endif
!         case(mtype_unres_symm_dense)
!             mat_sqnorm2 = mat_unres_symm_dense_sqnorm2(a)
         case(mtype_unres_dense)
             mat_sqnorm2 = mat_unres_dense_sqnorm2(a)
!         case(mtype_unres_sparse1)
!             mat_sqnorm2 = mat_unres_sparse1_sqnorm2(a)
         case default
              call lsquit("mat_sqnorm2 not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_sqnorm2: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_sqnorm2)

      END FUNCTION mat_sqnorm2

!> \brief Find the absolute largest element of a type(matrix).
!> \author S. Host
!> \date 2005
!> \param a The type(matrix) input
!> \param val The absolute largest element of a
      SUBROUTINE mat_abs_max_elm(a, val) 
         implicit none
         REAL(REALK),  INTENT(OUT)   :: val
         TYPE(Matrix), INTENT(IN)    :: a
!#ifdef HAVE_BSM
!         REAL(realk), external:: bsm_max
!#endif

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'Before mat_abs_max_elm: mem_allocated_global =', mem_allocated_global
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_abs_max_elm(a,val)
         case(mtype_dense)
             call mat_dense_abs_max_elm(a,val)
          case(mtype_csr)
             call mat_csr_abs_max_elm(a,val)
          case(mtype_scalapack)
             call mat_scalapack_abs_max_elm(a,val)
         case(mtype_sparse1)
             val = mat_sparse1_max_elm(A)
!            FIXME make
!            val = mat_sparse1_abs_max_elm(a)
!#ifdef HAVE_BSM
!         case(mtype_sparse_block)
!            val = bsm_abs_max(a)
!#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_abs_max_elm(a,val)
         case(mtype_unres_dense)
             call mat_unres_dense_abs_max_elm(a,val)
!         case(mtype_unres_sparse1)
         case default
              call lsquit("mat_abs_max_elm not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('MAXELM',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_abs_max_elm: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_abs_max_elm

!> \brief Find the largest element of a type(matrix).
!> \author S. Host
!> \date 2005
!> \param a The type(matrix) input
!> \param val The largest element of a
      SUBROUTINE mat_max_elm(a, val, pos) 
         implicit none
         REAL(REALK),  INTENT(OUT)   :: val
         TYPE(Matrix), INTENT(IN)    :: a
         integer, optional           :: pos(2)
         integer                     :: tmp(2)
#ifdef HAVE_BSM
         REAL(realk), external:: bsm_max
#endif

         if (info_memory) write(mat_lu,*) 'Before mat_max_elm: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_max_elm(a,val)
         case(mtype_dense)
             call mat_dense_max_elm(a,val,tmp)
          case(mtype_csr)
             if (present(pos)) call lsquit('mat_max_elm(): position parameter not implemented!',-1)
             call mat_csr_max_elm(a,val)
          case(mtype_scalapack)
             call mat_scalapack_max_elm(a,val,tmp)
#ifndef UNITTEST
         case(mtype_sparse1)
             if (present(pos)) call lsquit('mat_max_elm(): position parameter not implemented!',-1)
            val = mat_sparse1_max_elm(a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             if (present(pos)) call lsquit('mat_max_elm(): position parameter not implemented!',-1)
            val = bsm_max(a)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_max_elm(a,val)
         case(mtype_unres_dense)
             if (present(pos)) call lsquit('mat_max_elm(): position parameter not implemented!',-1)
             call mat_unres_dense_max_elm(a,val)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_max_elm(a,val)
         case default
              call lsquit('mat_max_elm not implemented for this type of matrix',-1)
         end select


         if (present(pos)) pos=tmp

         !if (INFO_TIME_MAT) CALL LSTIMER('MAXELM',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_max_elm: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_max_elm

      SUBROUTINE mat_min_elm(a, val, pos) 
         implicit none
         REAL(REALK),  INTENT(OUT)   :: val
         TYPE(Matrix), INTENT(IN)    :: a
         integer, optional           :: pos(2)
         integer                     :: tmp(2)

         if (info_memory) write(mat_lu,*) 'Before mat_min_elm: mem_allocated_global =', mem_allocated_global

         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_min_elm(a,val,tmp)
          case(mtype_scalapack)
             call mat_scalapack_min_elm(a,val,tmp)
         case default
              call lsquit("mat_max_elm not implemented for this type of matrix",-1)
         end select


         if (present(pos)) pos=tmp

         if (info_memory) write(mat_lu,*) 'After mat_min_elm: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_min_elm


!> \brief Find the largest element on the diagonal of a type(matrix).
!> \author S. Host
!> \date 2005
!> \param a The type(matrix) input
!> \param pos The position of the diagonal for the largest element of a
!> \param val The largest on element on the diagonal of a
      SUBROUTINE mat_max_diag_elm(a, pos, val) 
         implicit none
         TYPE(Matrix), INTENT(IN)    :: a
         INTEGER, INTENT(OUT)        :: pos
         REAL(REALK),  INTENT(OUT)   :: val

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (a%nrow /= a%ncol) then
           CALL LSQUIT( 'matrix must be symmetric in mat_max_diag_elm',-1)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_max_diag_elm(a,pos,val)
         case(mtype_dense)
             call mat_dense_max_diag_elm(a,pos,val)
         case(mtype_scalapack)
!             call mat_scalapack_max_diag_elm(a,pos,val)
!             print*,'the maximum element is',val
!             print*,'but the position is more complicated and '
!             print*,'not implemented.'
             call lsquit('mat_max_diag_elm not fully implemented for scalapack type matrix',-1)
!         case(mtype_sparse1)
!             call mat_sparse1_max_diag_elm(a,pos,val)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            CALL bsm_max_diag(a,pos,val)
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_max_diag_elm(a,pos,val)
         case(mtype_unres_dense)
             call mat_unres_dense_max_diag_elm(a,pos,val)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_max_diag_elm(a,pos,val)
         case default
              call lsquit("mat_max_diag_elm not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('MAXDIA',mat_TSTR,mat_TEN,mat_lu)
      END SUBROUTINE mat_max_diag_elm

!> \brief Squares all the off-diagonal elements in a type(matrix), and returns the sum
!> \author L. Thogersen
!> \date 2003
!> \param a The type(matrix) input
!> \return Sum of the squares of off-diagonal elements in a
      FUNCTION mat_outdia_sqnorm2(a)
         implicit none
         TYPE(Matrix), intent(IN) :: a
         REAL(realk) :: mat_outdia_sqnorm2
#ifdef HAVE_BSM
         REAL(realk), external:: bsm_outdia_sqnorm2
#endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             mat_outdia_sqnorm2 = mat_symm_dense_outdia_sqnorm2(a)
         case(mtype_dense)
             mat_outdia_sqnorm2 = mat_dense_outdia_sqnorm2(a)
         case(mtype_csr)
             mat_outdia_sqnorm2 = mat_csr_outdia_sqnorm2(a)
         case(mtype_scalapack)
             mat_outdia_sqnorm2 = mat_scalapack_outdia_sqnorm2(a)
#ifndef UNITTEST
         case(mtype_sparse1)
             mat_outdia_sqnorm2 = mat_sparse1_outdia_sqnorm2(a)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
             mat_outdia_sqnorm2 = bsm_outdia_sqnorm2(a)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             mat_outdia_sqnorm2 = mat_unres_symm_dense_outdia_sqnorm2(a)
         case(mtype_unres_dense)
             mat_outdia_sqnorm2 = mat_unres_dense_outdia_sqnorm2(a)
!         case(mtype_unres_sparse1)
!             mat_outdia_sqnorm2 = mat_unres_sparse1_outdia_sqnorm2(a)
         case default
              call lsquit("mat_outdia_sqnorm2 not implemented for this type of matrix",-1)
         end select
!         print *, "outdia got ", mat_outdia_sqnorm2
      END FUNCTION mat_outdia_sqnorm2

!> \brief General diagonalization F*C = S*C*e
!> \author L. Thogersen
!> \date 2003
!> \param F Fock/Kohn-Sham matrix
!> \param S Overlap matrix
!> \param eival Eigenvalues
!> \param Cmo C coefficients
      SUBROUTINE mat_diag_f(F,S,eival,Cmo)
         !solves FC = SCe 
         implicit none
         TYPE(Matrix), intent(IN) :: F,S
         type(matrix)             :: Cmo  !output
         real(realk),intent(INOUT)  :: eival(:)
!
         TYPE(MATRIX)             :: A,B 
         real(realk), allocatable :: tmp(:), eval(:), cmod(:), wrk(:)
         integer                  :: ndim

         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_diag_f(F,S,eival,Cmo)
         case(mtype_dense)
            call time_mat_operations1
            call mat_dense_diag_f(F,S,eival,Cmo)
            call time_mat_operations2(JOB_mat_diag_f)
         case(mtype_scalapack)
            call mat_init(A,F%nrow,F%ncol)
            call mat_init(B,S%nrow,S%ncol)
            call mat_copy(1E0_realk,F,A)
            call mat_copy(1E0_realk,S,B)
            call time_mat_operations1
            call mat_scalapack_diag_f(A,B,eival,Cmo)
            call time_mat_operations2(JOB_mat_diag_f)
            call mat_free(A)
            call mat_free(B)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_diag_f(F,S,eival,Cmo)
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_diag_f(F,S,eival,Cmo)
         case(mtype_unres_dense)
             call mat_unres_dense_diag_f(F,S,eival,Cmo)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_diag_f(F,S,eival,Cmo)
         case default
            print *, "FALLBACK diag_f...", S%nrow
            ndim = s%nrow
            ALLOCATE(tmp(Ndim*Ndim),eval(Ndim),cmod(Ndim*Ndim))
            call mat_to_full(S, 1E0_realk, tmp)
            call mat_to_full(F, 1E0_realk, cmod)
            call time_mat_operations1
            call my_DSYGV(ndim,cmod,tmp,eival,"mat_diag_f          ")
            call time_mat_operations2(JOB_mat_diag_f)
            call mat_set_from_full(cmod, 1E0_realk, Cmo)
            DEALLOCATE(tmp,eval,cmod)
         end select
     END SUBROUTINE mat_diag_f

!> \brief computes all eigenvalues and, eigenvectors of a real symmetric matrix S.
!> \author T. Kjaergaard
!> \date 2012
!> \param S matrix (input and output, output is the eigenvectors)
!> \param eival Eigenvalues (output vector)
      SUBROUTINE mat_dsyev(S,eival,ndim)
         implicit none
         TYPE(Matrix), intent(INOUT) :: S
         real(realk), intent(INOUT) :: eival(ndim)
!
         type(matrix) :: B
         real(realk),pointer :: work(:),S_full(:,:)
         integer :: infdiag,ndim,lwork

         select case(matrix_type)
!         case(mtype_symm_dense)
         case(mtype_dense)
            call time_mat_operations1
            call mat_dense_dsyev(S,eival,ndim)
            call time_mat_operations2(JOB_mat_dsyev)
         case(mtype_scalapack)
            call mat_init(B,S%nrow,S%ncol)
            call time_mat_operations1
            call mat_scalapack_dsyev(S,B,eival,ndim)
            call time_mat_operations2(JOB_mat_dsyev)
            call mat_assign(S,B)
            call mat_free(B)
         case(mtype_unres_dense)
            call mat_unres_dense_dsyev(S,eival,ndim)
!            call lsquit('mat_dsyev not implemented for unres',-1)
!         case(mtype_unres_sparse1)
         case default
            call mem_alloc(S_full,ndim,ndim)
            call mat_to_full(S,1.0E0_realk,S_full)
            !============================================================
            ! we inquire the size of lwork
            lwork = -1
            call mem_alloc(work,5)
            call time_mat_operations1
            call dsyev('V','U',ndim,S_FULL,ndim,eival,work,lwork,infdiag)
            lwork = NINT(work(1))
            call mem_dealloc(work)
            !=============================================================     
            call mem_alloc(work,lwork)
            !diagonalization
            call dsyev('V','U',ndim,S_FULL,ndim,eival,work,lwork,infdiag)
            call time_mat_operations2(JOB_mat_dsyev)
            call mem_dealloc(work)
            call mat_set_from_full(S_FULL, 1E0_realk,S)
            call mem_dealloc(S_full)
            if(infdiag.ne. 0) then
               print*,'lowdin_diag: dsyev failed, info=',infdiag
               call lsquit('lowdin_diag: diagonalization failed.',-1)
            end if
         end select
       END SUBROUTINE mat_dsyev
 
!> \brief computes one specific eigenvalue of a real symmetric matrix S.
!> \author S. Reine
!> \date May 2012
!> \param S matrix (input and output, output is the eigenvectors)
!> \param eival Eigenvalue
!> \param ieig Index of the eigenvalue to be returned (in acending order)
  SUBROUTINE mat_dsyevx(S,eival,ieig)
    implicit none
    TYPE(Matrix), intent(INOUT) :: S
    real(realk), intent(INOUT)  :: eival
    integer,intent(in)          :: ieig
!
    integer             :: ndim
    real(realk),pointer :: Sfull(:,:)
!
    select case(matrix_type)
    case(mtype_dense)
    call time_mat_operations1           
    CALL mat_dense_dsyevx(S,eival,ieig)
    call time_mat_operations2(JOB_mat_dsyevx)
    case(mtype_scalapack)
    call time_mat_operations1           
      CALL mat_scalapack_dsyevx(S,eival,ieig)
    call time_mat_operations2(JOB_mat_dsyevx)
    case default
      write(*,*) 'FALLBACK: mat_dsyevx'
      ndim = S%nrow
      call mem_alloc(Sfull,ndim,ndim)
      call mat_to_full(S,1.0E0_realk,Sfull)
      call time_mat_operations1           
      CALL mat_dense_dsyevx_aux(Sfull,eival,ndim,ieig)
      call time_mat_operations2(JOB_mat_dsyevx)
      call mem_dealloc(Sfull)
    end select
  END SUBROUTINE mat_dsyevx

!> \brief Returns a section of a matrix
!> \author L. Thogersen
!> \date 2003
!> \param A Input type(matrix)
!> \param from_row Begin at this row
!> \param to_row End at this row
!> \param from_col Begin at this column
!> \param to_col End at this column
!> \param Asec The section of the type(matrix)
    subroutine mat_section(A,from_row,to_row,from_col,to_col,Asec)
      implicit none
      type(Matrix), intent(in) :: A
      integer, intent(in) :: from_row, to_row, from_col, to_col
      type(Matrix), intent(inout) :: Asec  !output
      
      !Check if Asec is inside A
      if (to_row > A%nrow .or. from_row < 1 .or. from_col < 1 .or. A%ncol < to_col) then
         call lsquit('Asec not inside A in mat_section',-1)
      endif
      !Check if the section size is positive
      if (from_row > to_row .or. from_col > to_col) then
         call lsquit('from_row or from_col > to_row or to_col in mat_section',-1)
      endif
      !Check if allocated space for section is the right size
      if (Asec%nrow /= to_row - from_row + 1 .or.&
           & Asec%ncol /= to_col - from_col + 1) then
         CALL LSQUIT( 'Wrong dimensions in mat_section',-1)
      endif
      
      select case(matrix_type)
         !         case(mtype_symm_dense)
         !             call mat_symm_dense_section(A,from_row,to_row,from_col,to_col,Asec)
      case(mtype_dense)
         call mat_dense_section(A,from_row,to_row,from_col,to_col,Asec)
#ifndef UNITTEST
      case(mtype_sparse1)
         call mat_sparse1_section(A,from_row,to_row,from_col,to_col,Asec)
#endif
         !         case(mtype_unres_symm_dense)
         !             call mat_unres_symm_dense_section(A,from_row,to_row,from_col,to_col,Asec)
      case(mtype_unres_dense)
         call mat_unres_dense_section(A,from_row,to_row,from_col,to_col,Asec)
         !         case(mtype_unres_sparse1)
         !             call mat_unres_sparse1_section(A,from_row,to_row,from_col,to_col,Asec)
      case default
         call lsquit("mat_section not implemented for this type of matrix",-1)
      end select
    END SUBROUTINE mat_section
   
!> \brief Inserts (overwrites) a matrix-section into at matrix (like mat_section but opposite)
!> \author C. Nygaard
!> \date June 11 2012
!> \param Asec The section to be inserted
!> \param from_row Begin at this row
!> \param to_row End at this row
!> \param from_col Begin at this column
!> \param to_col End at this column
!> \param A The matrix into which the section is inserted
subroutine mat_insert_section (Asec, from_row, to_row, from_col, to_col, A)

implicit none

type(matrix), intent(in)    :: Asec
integer, intent(in)         :: from_row, to_row, from_col, to_col
type(matrix), intent(inout) :: A

!Check if Asec is inside A
if (to_row > A%nrow .or. from_row < 1 .or. from_col < 1 .or. A%ncol < to_col) then
   CALL LSQUIT( 'Asec not inside A in mat_insert_section',-1)
endif
!Check if the section size is positive
if (from_row > to_row .or. from_col > to_col) then
   CALL LSQUIT( 'from_row or from_col > to_row or to_col in mat_insert_section',-1)
endif
!Check if allocated space for section is the right size
if (Asec%nrow /= to_row - from_row + 1 .or.&
     & Asec%ncol /= to_col - from_col + 1) then
   CALL LSQUIT( 'Wrong dimensions in mat_insert_section',-1)
endif

select case(matrix_type)
case (mtype_dense)
  call mat_dense_insert_section (Asec, from_row, to_row, from_col, to_col, A)
case(mtype_unres_dense)
  call mat_unres_dense_insert_section (Asec, from_row, to_row, from_col, to_col, A)
case default
  call lsquit("mat_insert_section not implemented for this type of matrix",-1)
end select

end subroutine mat_insert_section
 
!> \brief Set a type(matrix) to identity, i.e. I(i,j) = 1 for i = j, 0 otherwise
!> \author L. Thogersen
!> \date 2003
!> \param I Matrix to be set equal to identity
      subroutine mat_identity(I)
         implicit none
         type(Matrix), intent(inout) :: I
         real(realk), ALLOCATABLE    :: ifull(:,:)
         integer                     :: j
         !
         type(Matrix) :: TMP

         if (info_memory) write(mat_lu,*) 'Before mat_identity: mem_allocated_global =', mem_allocated_global
         !print *, "mat_identity inefficient, use mat_add_identity instead!"
         if (I%nrow /= I%ncol) then
           CALL LSQUIT( 'cannot make identity matrix with different ncol and nrow',-1)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_identity(I)
         case(mtype_dense)
             call time_mat_operations1
             call mat_dense_identity(I)
             call time_mat_operations2(JOB_mat_identity)
         case(mtype_csr)
             call time_mat_operations1
             call mat_csr_identity(I)
             call time_mat_operations2(JOB_mat_identity)
         case(mtype_scalapack)
             call time_mat_operations1
            call mat_scalapack_add_identity(1E0_realk,0E0_realk,TMP,I)
             call time_mat_operations2(JOB_mat_identity)
#ifndef UNITTEST
         case(mtype_sparse1)
             call time_mat_operations1
             call mat_sparse1_identity(I)
             call time_mat_operations2(JOB_mat_identity)
#if defined(HAVE_BSM)
         case(mtype_sparse_block)
             call time_mat_operations1
            call bsm_identity(I)
             call time_mat_operations2(JOB_mat_identity)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_identity(I)
         case(mtype_unres_dense)
             call time_mat_operations1
             call mat_unres_dense_identity(I)
             call time_mat_operations2(JOB_mat_identity)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_identity(I)
         case default
            call time_mat_operations1
            print *, "FALLBACK: mat_identity"
            allocate(ifull(I%nrow, I%ncol))
            DO j = 1, I%ncol
               ifull(1:j-1,j) = 0E0_realk
               ifull(j,j)     = 1E0_realk
               ifull(j+1:I%nrow,j) = 0E0_realk
            END DO
            call time_mat_operations2(JOB_mat_identity)
            call mat_set_from_full(ifull,1E0_realk,I)
            deallocate(ifull)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_identity: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_identity

!> \brief Add identity to a type(matrix), i.e. C = alpha*I + beta*B  >>> NOTE: ALLOCATES A MATRIX! <<<
!> \author L. Thogersen
!> \date 2003
!> \param alpha Alpha parameter
!> \param beta Beta parameter
!> \param B Input matrix B
!> \param C Output matrix C
      SUBROUTINE mat_add_identity(alpha, beta, B, C)
         implicit none
         TYPE(Matrix), intent(IN) :: B
         REAL(realk), INTENT(IN)  :: alpha, beta
         TYPE(Matrix)             :: C
         type(matrix)             :: I

         if (info_memory) write(mat_lu,*) 'Before mat_add_identity: mem_allocated_global =', mem_allocated_global
         if (b%nrow /= c%nrow .or. b%ncol /= c%ncol) then
           CALL LSQUIT( 'wrong dimensions in mat_add_identity',-1)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_add(alpha,a,beta,b,c)
         case(mtype_dense)
            call mat_init(I, b%nrow, b%ncol)
            call mat_dense_identity(I)
            call mat_dense_add(alpha,I,beta,b,c)
            call mat_free(I)
         case(mtype_csr)
            call mat_csr_add_identity(alpha, beta, B, C)
         case(mtype_scalapack)
            call mat_scalapack_add_identity(alpha, beta, B, C)
#ifndef UNITTEST
         case(mtype_sparse1)
            call mat_init(I, b%nrow, b%ncol)
            call mat_sparse1_identity(I)
            call mat_sparse1_add(alpha,I,beta,b,c)
            call mat_free(I)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            c = B
            call mat_scal(beta, c)
            call bsm_add_identity(c, alpha)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_add(alpha,a,beta,b,c)
         case(mtype_unres_dense)
            call mat_init(I, b%nrow, b%ncol)
            call mat_unres_dense_identity(I)
            call mat_unres_dense_add(alpha,I,beta,b,c)
            call mat_free(I)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_add(alpha,a,beta,b,c)
         case default
              call lsquit("mat_add_identity not implemented for this type of matrix",-1)
         end select
         if (info_memory) write(mat_lu,*) 'After mat_add_identity: mem_allocated_global =', mem_allocated_global
      END SUBROUTINE mat_add_identity

!> \brief Create or overwrite block in a type(matrix)
!> \author S. Host
!> \date 2009
!> \param A Input/output matrix where we want to create a block
!> \param fullmat Standard fortran matrix containing the block to put into A
!> \param fullrow Number of rows in fullmat
!> \param fullcol Number of columns in fullmat
!> \param insertrow Insert block in A beginning at this row
!> \param insertcol Insert block in A beginning at this col
      subroutine mat_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in) :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(in) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (insertrow+fullrow > A%nrow+1 .or. &
          &  insertcol+fullcol > A%ncol+1 .or. fullrow < 1 .or. fullcol < 1 .or. &
          & insertrow < 1 .or. insertcol < 1) then
           WRITE(mat_lu,*) 'Cannot create block, the indexes', &
           & fullrow,fullcol,insertrow,insertcol, &
           & 'are out of the bounds - nrow, ncol =',A%nrow,A%ncol
           CALL lsQUIT('Cannot create block (subroutine mat_create_block)',mat_lu)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_dense)
             call mat_dense_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            print *, "FALLBACK: mat_create_block converts to full for Block Sparse Matrices"
            call mat_create_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_unres_dense)
             call mat_unres_dense_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_scalapack)
              call mat_scalapack_create_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case default
              call lsquit("mat_create_block not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('CREATE',mat_TSTR,mat_TEN,mat_lu)

         call time_mat_operations2(JOB_mat_create_block)
       contains
         subroutine mat_create_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in) :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(in) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         real(realk), allocatable :: Afull(:,:)
         integer                  :: i, j

         call lsquit( 'inside mat_create_block_bsm_fallback',-1)
         allocate(Afull(A%nrow,A%ncol))
         call mat_to_full(A,1.0E0_realk,Afull)

         do i = insertrow, insertrow+fullrow-1
            do j = insertcol, insertcol+fullcol-1
               Afull(i,j) = fullmat(i-insertrow+1,j-insertcol+1)
            enddo
         enddo

         call mat_set_from_full(Afull,1.0E0_realk,A) 
         deallocate(Afull)

         end subroutine mat_create_block_bsm_fallback

      END SUBROUTINE mat_create_block

!> \brief Add block to type(matrix) - add to existing elements, don't overwrite
!> \author T. Kjaergaard
!> \date 2009
!> \param A Input/output matrix where we want to add a block
!> \param fullmat Standard fortran matrix containing the block to add to A
!> \param fullrow Number of rows in fullmat
!> \param fullcol Number of columns in fullmat
!> \param insertrow Add block to A beginning at this row
!> \param insertcol Add block to A beginning at this col
      subroutine mat_add_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in) :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(inout) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (insertrow+fullrow > A%nrow+1 .or. &
          &  insertcol+fullcol > A%ncol+1 .or. fullrow < 1 .or. fullcol < 1 .or. &
          & insertrow < 1 .or. insertcol < 1) then
           WRITE(mat_lu,*) 'Cannot add block, the indexes', &
           & fullrow,fullcol,insertrow,insertcol, &
           & 'are out of the bounds - nrow, ncol =',A%nrow,A%ncol
           CALL lsQUIT('Cannot add block (subroutine mat_add_block)',mat_lu)
         endif
         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_add_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_add_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            print *, "FALLBACK: mat_add_block converts to full for Block Sparse Matrices"
            call mat_add_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#endif
#endif
         case(mtype_scalapack)
            call mat_scalapack_add_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_unres_dense)
             call mat_unres_dense_add_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case default
              call lsquit("mat_add_block not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('CREATE',mat_TSTR,mat_TEN,mat_lu)

         call time_mat_operations2(JOB_mat_add_block)
       contains
         subroutine mat_add_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in) :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(in) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         real(realk), allocatable :: Afull(:,:)
         integer                  :: i, j

         allocate(Afull(A%nrow,A%ncol))
         call mat_to_full(A,1.0E0_realk,Afull)

         do i = insertrow, insertrow+fullrow-1
            do j = insertcol, insertcol+fullcol-1
               Afull(i,j) = Afull(i,j)+fullmat(i-insertrow+1,j-insertcol+1)
            enddo
         enddo

         call mat_set_from_full(Afull,1.0E0_realk,A) 
         deallocate(Afull)

       end subroutine mat_add_block_bsm_fallback

     END SUBROUTINE mat_add_block

!> \brief Retrieve block from type(matrix) 
!> \author T. Kjaergaard
!> \date 2009
!> \param A Input matrix from which we want to retrive a block
!> \param fullmat Return the desired block in this standard fortran matrix
!> \param fullrow Number of rows in fullmat
!> \param fullcol Number of columns in fullmat
!> \param insertrow Retrive block from A beginning at this row
!> \param insertcol Retrive block from A beginning at this col
      subroutine mat_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in) :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(inout) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         call time_mat_operations1

         if (info_memory) write(mat_lu,*) 'Before mat_retrieve_block: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (insertrow+fullrow > A%nrow+1 .or. &
          &  insertcol+fullcol > A%ncol+1 .or. fullrow < 1 .or. fullcol < 1 .or. &
          & insertrow < 1 .or. insertcol < 1) then
           WRITE(mat_lu,*) 'Cannot retrieve block, the indexes', &
           & fullrow,fullcol,insertrow,insertcol, &
           & 'are out of the bounds - nrow, ncol =',A%nrow,A%ncol
           CALL lsQUIT('Cannot retrieve block (subroutine mat_retrieve_block)',mat_lu)
         endif
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_dense)
             call mat_dense_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_csr)
             call mat_csr_retrieve_block_full(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_scalapack)
            call mat_scalapack_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            print *, "FALLBACK: mat_retrieve_block converts to full for Block Sparse Matrices"
            call mat_retrieve_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case(mtype_unres_dense)
             call mat_unres_dense_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_retrieve_block(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         case default
              call lsquit("mat_retrieve_block not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('CREATE',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_retrieve_block: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_retrieve_block)

       contains
         subroutine mat_retrieve_block_bsm_fallback(A,fullmat,fullrow,fullcol,insertrow,insertcol)
         implicit none
         integer, intent(in)      :: fullrow,fullcol,insertrow,insertcol
         real(Realk), intent(out) :: fullmat(fullrow,fullcol)
         type(Matrix), intent(inout) :: A
         real(realk), allocatable :: Afull(:,:)
         integer                  :: i, j
         allocate(Afull(A%nrow,A%ncol))
         call mat_to_full(A,1.0E0_realk,Afull)

         do i = insertrow, insertrow+fullrow-1
            do j = insertcol, insertcol+fullcol-1
                fullmat(i-insertrow+1,j-insertcol+1) = Afull(i,j)
            enddo
         enddo

         deallocate(Afull)

       end subroutine mat_retrieve_block_bsm_fallback
     END SUBROUTINE mat_retrieve_block

!> \brief Scale a type(matrix) A by a scalar alpha
!> \author L. Thogersen
!> \date 2003
!> \param alpha Scaling parameter
!> \param A Input/output matrix which we want to scale
      subroutine mat_scal(alpha,A)
         implicit none
         real(realk), intent(in) :: alpha
         type(Matrix), intent(inout) :: A
         call time_mat_operations1

         if (info_memory) write(mat_lu,*) 'Before mat_scal: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_scal(alpha,A)
         case(mtype_dense)
             call mat_dense_scal(alpha,A)
         case(mtype_csr)
             call mat_csr_scal(alpha, A)
         case(mtype_scalapack)
             call mat_scalapack_scal(alpha, A)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_scal(alpha,A)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            call bsm_scal(alpha, A)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_scal(alpha,A)
         case(mtype_unres_dense)
             call mat_unres_dense_scal(alpha,A)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_scal(alpha,A)
         case default
              call lsquit("mat_scal not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('SCAL  ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_scal: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_scal)

      end subroutine mat_scal

!> \brief Scale the diagonal of a type(matrix) A by a scalar alpha
!> \author L. Thogersen
!> \date 2003
!> \param alpha Scaling parameter
!> \param A Input/output matrix which we want to scale
      subroutine mat_scal_dia(alpha,A)
         implicit none
         real(realk), intent(in) :: alpha
         type(Matrix), intent(inout) :: A
         real(realk), allocatable :: afull(:,:)
         integer i
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (A%nrow /= A%ncol) then
           CALL LSQUIT( 'cannot scale diagonal since ncol /= nrow',-1)
         endif

         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_scal_dia(alpha,A)
#ifndef UNITTEST
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            CALL bsm_scal_dia(alpha, A)
#endif
         case(mtype_sparse1)
             call mat_sparse1_scal_dia(alpha,A)
#endif
         case(mtype_unres_dense)
             call mat_unres_dense_scal_dia(alpha,A)
         case(mtype_scalapack)
            call mat_scalapack_scal_dia(alpha,A)
         case default
            print *, "FALLBACK scale_dia"
            allocate(afull(a%nrow, a%ncol))
            call mat_to_full(a,1E0_realk,afull)
            do i = 1,A%nrow
               afull(i,i) = afull(i,i) * alpha
            enddo
            call mat_set_from_full(afull, 1E0_realk, a)
            DEALLOCATE(afull)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('SCADIA',mat_TSTR,mat_TEN,mat_lu)
         call time_mat_operations2(JOB_mat_scal_dia)
      end subroutine mat_scal_dia

!> \brief Scale the diagonal with a vector
!> \author T. Kjaergaard
!> \date 2012
!> \param alpha Scaling parameter
!> \param A Input/output matrix which we want to scale
      subroutine mat_scal_dia_vec(alpha,A,ndim)
         implicit none
         integer, intent(in)     :: ndim
         real(realk), intent(in) :: alpha(ndim)
         type(Matrix), intent(inout) :: A
         real(realk), allocatable :: afull(:,:)
         integer i
         call time_mat_operations1

         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         if (A%nrow /= A%ncol) then
           CALL LSQUIT( 'cannot scale diagonal since ncol /= nrow',-1)
         endif

         select case(matrix_type)
         case(mtype_dense)
             call mat_dense_scal_dia_vec(alpha,A,ndim)
         case(mtype_scalapack)
            call mat_scalapack_scal_dia_vec(alpha,A,ndim)
         case default
            print *, "FALLBACK scale_dia"
            allocate(afull(a%nrow, a%ncol))
            call mat_to_full(a,1E0_realk,afull)
            do i = 1,A%nrow
               afull(i,i) = afull(i,i) * alpha(i)
            enddo
            call mat_set_from_full(afull, 1E0_realk, a)
            DEALLOCATE(afull)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('SCADIA',mat_TSTR,mat_TEN,mat_lu)
         call time_mat_operations2(JOB_mat_scal_dia_vec)
      end subroutine mat_scal_dia_vec

!> \brief Set a type(matrix) A to zero
!> \author L. Thogersen
!> \date 2003
!> \param A Input/output matrix which should be set to zero
      subroutine mat_zero(A)
         implicit none
         type(Matrix), intent(inout) :: A
         call time_mat_operations1

         if (info_memory) write(mat_lu,*) 'Before mat_zero: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         select case(matrix_type)
!         case(mtype_symm_dense)
!             call mat_symm_dense_zero(A)
         case(mtype_dense)
             call mat_dense_zero(A)
         case(mtype_scalapack)
             call mat_scalapack_zero(A)
#ifndef UNITTEST
         case(mtype_sparse1)
             call mat_sparse1_zero(A)
#ifdef HAVE_BSM
         case(mtype_sparse_block)
            call bsm_scal(0E0_realk, A)
#endif
#endif
!         case(mtype_unres_symm_dense)
!             call mat_unres_symm_dense_zero(A)
         case(mtype_unres_dense)
             call mat_unres_dense_zero(A)
         case(mtype_csr)
             call mat_csr_zero(A)
!         case(mtype_unres_sparse1)
!             call mat_unres_sparse1_zero(A)
         case default
              call lsquit("mat_zero not implemented for this type of matrix",-1)
         end select
         !if (INFO_TIME_MAT) CALL LSTIMER('ZERO  ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_zero: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_zero)

      end subroutine mat_zero

!> \brief Set the lower triangular part of type(matrix) A to zero
!> \author T. Kjaergaard
!> \date 2012
!> \param A Input/output matrix which should be set to zero
subroutine mat_setlowertriangular_zero(A)
  implicit none
  type(Matrix), intent(inout) :: A
!
  real(realk),pointer :: Afull(:,:)
  call time_mat_operations1
  
  if (info_memory) write(mat_lu,*) 'Before mat_zero: mem_allocated_global =',&
       &mem_allocated_global
  select case(matrix_type)
  case(mtype_dense)
     call set_lowertriangular_zero(A%elms,A%nrow,A%ncol)
  case(mtype_unres_dense)
     call set_lowertriangular_zero(A%elms,A%nrow,A%ncol)
     call set_lowertriangular_zero(A%elmsb,A%nrow,A%ncol)
  case(mtype_scalapack)
     call mat_scalapack_setlowertriangular_zero(A)
  case default
     print*,'Fallback mat_setlowertriangular_zero'
     allocate(afull(a%nrow, a%ncol))
     call mat_to_full(a,1E0_realk,afull)     
     call set_lowertriangular_zero(Afull,A%nrow,A%ncol)
     deallocate(afull)
  end select
  if (info_memory) write(mat_lu,*) 'After mat_zero: mem_allocated_global =',&
       & mem_allocated_global
  call time_mat_operations2(JOB_mat_setlowertriangular_zero)  
end subroutine mat_setlowertriangular_zero

subroutine set_lowertriangular_zero(elms,dimenA,dimenB)
  implicit none
  integer,intent(in) :: dimenA,dimenB
  real(realk) :: elms(dimenA,dimenB)
  !
  integer :: A,B
  DO B=1,dimenB
     DO A=B+1,dimenA
        elms(A,B) = 0.0E0_realk
     ENDDO
  ENDDO
end subroutine set_lowertriangular_zero

!> \brief Write a type(matrix) to disk.
!> \author L. Thogersen
!> \date 2003
!> \param iunit Logical unit number of file which matrix should be written to
!> \param A Matrix which should be written on disk
      subroutine mat_write_to_disk(iunit,A,OnMaster)
         implicit none
         integer, intent(in) :: iunit
         type(Matrix), intent(in) :: A
         logical,intent(in) :: OnMaster
         !
         real(realk), allocatable :: afull(:,:)
#ifdef HAVE_BSM
         external mat_write_int, mat_write_real
#endif
         call time_mat_operations1

         if (info_memory) write(mat_lu,*) 'Before mat_write_to_disk: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         IF(OnMaster)THEN
            select case(matrix_type)
               !         case(mtype_symm_dense)
               !             call mat_symm_dense_write_to_disk(iunit,A)
            case(mtype_dense)
               call mat_dense_write_to_disk(iunit,A)
            case(mtype_csr)
               call mat_csr_write_to_disk(iunit,A)
#ifndef UNITTEST
            case(mtype_sparse1)
               call mat_sparse1_write_to_disk(iunit,A)
#ifdef HAVE_BSM
            case(mtype_sparse_block)
               call bsm_write_to_unit(iunit,A,mat_write_int,mat_write_real)
#endif
#endif
            case(mtype_scalapack)
               !The master collects the info and write to disk
               allocate(afull(a%nrow, a%ncol))
               call mat_to_full(a,1E0_realk,afull)
               write(iunit) A%Nrow, A%Ncol
               write(iunit) afull
               deallocate(afull)
               !         case(mtype_unres_symm_dense)
               !             call mat_unres_symm_dense_write_to_disk(iunit,A)
            case(mtype_unres_dense)
               call mat_unres_dense_write_to_disk(iunit,A)
               !         case(mtype_unres_sparse1)
               !             call mat_unres_sparse1_write_to_disk(iunit,A)
            case default
               print *, "FALLBACK: mat_write_to_disk"
               allocate(afull(a%nrow, a%ncol))
               call mat_to_full(a,1E0_realk,afull)
               write(iunit) A%Nrow, A%Ncol
               write(iunit) afull
               deallocate(afull)
            end select
         ELSE
            !write to own memory
            call matrixmembuf_write_to_mem(iunit,A)
         ENDIF

         !if (INFO_TIME_MAT) CALL LSTIMER('WRITE ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_write_to_disk: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_write_to_disk)

      end subroutine mat_write_to_disk


!> \brief Add some logical auxiliary information to a type(matrix) on disk.
!> \author S. Host
!> \date June 2010
!> \param iunit Logical unit number of file containing the matrix
!> \param info Info to be written
!>
!> This is needed because the dens.restart that is dumped after calculatation
!> has ended can be either in the standard AO basis or the grand-canonical
!> basis. A dens.restart obtained from in the AO basis will not work in the
!> grand-canonical basis and vice versa. For the moment, it is only possible
!> to put true or false here, but that could easily be changed to a character
!> string saying e.g. 'AOBASIS', 'GCBASIS', or whatever other basis you could
!> think of. Should be independent of matrix type.
!> Must only be called after the matrix has been written and before 
!> file is rewinded!
!>
      subroutine mat_write_info_to_disk(iunit,info)
         implicit none
         integer, intent(in) :: iunit
         logical, intent(in) :: info

      write(iunit) info
      end subroutine mat_write_info_to_disk

!> \brief Read a type(matrix) from disk.
!> \author L. Thogersen
!> \date 2003
!> \param iunit Logical unit number of file from which matrix should be read
!> \param A Output matrix which is read from disk
      subroutine mat_read_from_disk(iunit,A,OnMaster)
         implicit none
         integer, intent(in) :: iunit
         type(Matrix), intent(inout) :: A  !output
         logical,intent(in) :: OnMaster
         !
         real(realk), allocatable :: afull(:,:)
         integer                  :: nrow, ncol
#ifdef HAVE_BSM
         external mat_read_int, mat_read_real
#endif
         call time_mat_operations1
         if (info_memory) write(mat_lu,*) 'Before mat_read_from_disk: mem_allocated_global =', mem_allocated_global
         !if (INFO_TIME_MAT) CALL LSTIMER('START ',mat_TSTR,mat_TEN,mat_lu)
         IF(OnMaster)THEN
            select case(matrix_type)
               !         case(mtype_symm_dense)
               !             call mat_symm_dense_read_from_disk(iunit,A)
            case(mtype_dense)
               call mat_dense_read_from_disk(iunit,A)
            case(mtype_csr)
               call mat_csr_read_from_disk(iunit,A)
#ifndef UNITTEST
            case(mtype_sparse1)
               call mat_sparse1_read_from_disk(iunit,A)
#ifdef HAVE_BSM
            case(mtype_sparse_block)
               call bsm_read_from_unit(iunit,A,mat_read_int,mat_read_real)
#endif
#endif
            case(mtype_scalapack)
               !The master Read full matrix from disk 
               print *, "FALLBACK: mat_read_from_disk"
               allocate(afull(a%nrow, a%ncol))
               READ(iunit) Nrow, Ncol
               if(Nrow /= A%nrow) call lsquit( 'mat_read_from_disk: Nrow /= A%nrow',-1)
               if(Ncol /= A%ncol) call lsquit( 'mat_read_from_disk: Ncol /= A%ncol',-1)
               read(iunit) afull
               call mat_set_from_full(afull,1E0_realk,a)
               deallocate(afull)
               !         case(mtype_unres_symm_dense)
               !             call mat_unres_symm_dense_read_from_disk(iunit,A)
            case(mtype_unres_dense)
               call mat_unres_dense_read_from_disk(iunit,A)
               !         case(mtype_unres_sparse1)
               !             call mat_unres_sparse1_read_from_disk(iunit,A)
            case default
               print *, "FALLBACK: mat_read_from_disk"
               allocate(afull(a%nrow, a%ncol))
               READ(iunit) Nrow, Ncol
               if(Nrow /= A%nrow) call lsquit( 'mat_read_from_disk: Nrow /= A%nrow',-1)
               if(Ncol /= A%ncol) call lsquit( 'mat_read_from_disk: Ncol /= A%ncol',-1)
               read(iunit) afull
               call mat_set_from_full(afull,1E0_realk,a)
               deallocate(afull)
            end select
         ELSE
            !reads from buffer 
            call matrixmembuf_read_from_mem(iunit,A)
         ENDIF

         !if (INFO_TIME_MAT) CALL LSTIMER('READ  ',mat_TSTR,mat_TEN,mat_lu)
         if (info_memory) write(mat_lu,*) 'After mat_read_from_disk: mem_allocated_global =', mem_allocated_global
         call time_mat_operations2(JOB_mat_read_from_disk)

      end subroutine mat_read_from_disk

!> \brief Read some logical auxiliary information from a type(matrix) on disk.
!> \author S. Host
!> \date June 2010
!> \param iunit Logical unit number of file containing the matrix
!> \param info Info to be read
!>
!> See description in mat_write_info_to_disk.
!>
      subroutine mat_read_info_from_disk(iunit,info)
        implicit none
        integer, intent(in)  :: iunit
        logical, intent(out) :: info
        read(iunit) info
      end subroutine mat_read_info_from_disk

!> \brief Extract diagonal of A, store in dense vector vec.
!> \author B. Jansik
!> \date 2010
!> \param A The type(matrix) input
!> \param diag vector to hold the diagonal
    subroutine mat_extract_diagonal (diag,A)
      implicit none
      type(Matrix), intent(in) :: A
      real(realk), intent(inout) :: diag(A%nrow)

      select case(matrix_type)
      case(mtype_dense)
           call mat_dense_extract_diagonal(diag,A)
      case(mtype_scalapack)
           call mat_scalapack_extract_diagonal(diag,A)
      case default
            call lsquit("mat_extract_diagonal not implemented for this type of matrix",-1)
      end select

    end subroutine mat_extract_diagonal

    !Matrix Memory buffer Framework to write to memory

    subroutine matrixmembuf_init()
      implicit none
      nullify(matmembuf%fileliststart)
      nullify(matmembuf%filelistend)
    end subroutine matrixmembuf_init

    !==========================================
    !matrixmembuf_new_iunit
    !==========================================
    subroutine matrixmembuf_new_iunit(filename,iunit)
      integer :: iunit
      character(len=80) :: filename
      !
      logical :: found
      iunit = 50
      Found = .FALSE.
      DO 
         call FindIunit(iunit,Found)
         IF(Found)THEN
            iunit = iunit+1
            Found=.FALSE.
         ELSE
            EXIT
         ENDIF
      ENDDO
    end subroutine matrixmembuf_new_iunit
    subroutine FindIunit(iunit,Found)
      implicit none
      integer :: iunit
      logical :: Found        
      IF(associated(matmembuf%fileliststart))THEN
         call FindIunitFileUnit(matmembuf%fileliststart,iunit,Found)
      ENDIF
    end subroutine FindIunit
    recursive subroutine FindIunitFileUnit(item,iunit,Found)
      implicit none
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      IF(item%iunit.EQ.iunit)THEN
         Found = .TRUE.
      ELSEIF(associated(item%filenext))THEN
         call FindIunitFileUnit(item%filenext,iunit,Found)
      ENDIF
    end subroutine FindIunitFileUnit

    subroutine matrixmembuf_FindFile(filename,iunit,Found)
      integer :: iunit
      character(len=80) :: filename
      logical :: found
      Found = .FALSE.
      call FindIunit2(iunit,Found,filename)
    end subroutine matrixmembuf_FindFile
    subroutine FindIunit2(iunit,Found,filename)
      implicit none
      integer :: iunit
      logical :: Found        
      character(len=80) :: filename
      IF(associated(matmembuf%fileliststart))THEN
         call FindIunitFileUnit2(matmembuf%fileliststart,iunit,Found,filename)
      ENDIF
    end subroutine FindIunit2
    recursive subroutine FindIunitFileUnit2(item,iunit,Found,filename)
      implicit none
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      character(len=80) :: filename
      IF(item%filename.EQ.filename)THEN
         iunit=item%iunit
         Found = .TRUE.
      ELSEIF(associated(item%filenext))THEN
         call FindIunitFileUnit2(item%filenext,iunit,Found,filename)
      ENDIF
    end subroutine FindIunitFileUnit2

    subroutine matrixmembuf_setmatrixcurrent(iunit)
      integer :: iunit
      call setmatrixcurrent1(matmembuf%fileliststart,iunit)
    end subroutine Matrixmembuf_setmatrixcurrent
    recursive subroutine setmatrixcurrent1(item,iunit)
      implicit none
      integer :: iunit
      type(matrixfiletype) :: item
      IF(item%iunit.EQ.iunit)THEN
         item%matrixcurrent => item%matrixliststart
      ELSEIF(associated(item%filenext))THEN
         call Setmatrixcurrent1(item%filenext,iunit)
      ENDIF
    end subroutine Setmatrixcurrent1

    !==========================================
    !matrixmembuf_free
    !==========================================
    subroutine matrixmembuf_free()
      IF(associated(matmembuf%fileliststart))THEN
         call free_FileUnit(matmembuf%fileliststart)
         nullify(matmembuf%fileliststart)
         nullify(matmembuf%filelistend)
      ENDIF
    end subroutine matrixmembuf_free
    recursive subroutine Free_fileUnit(fileitem)
      implicit none
      type(matrixfiletype) :: fileitem
      IF(associated(fileitem%matrixliststart))THEN
         call Free_filematrix(fileitem%matrixliststart)
         nullify(fileitem%matrixliststart)
         nullify(fileitem%matrixlistend)
      ENDIF
      IF(associated(fileitem%filenext))THEN
         call Free_fileUnit(fileitem%filenext)
         nullify(fileitem%filenext)
      ENDIF
    end subroutine Free_fileUnit
    recursive subroutine Free_fileMatrix(matitem)
      type(matrixfiletype2) :: matitem
      IF(associated(matitem%matnext))THEN
         call Free_FileMatrix(matitem%matnext)
         nullify(matitem%matnext)
      ENDIF
      call mat_free(matitem%mat)
    end subroutine Free_fileMatrix

    !==========================================
    !matrixmembuf_print
    !==========================================
    subroutine matrixmembuf_print(lupri)
      integer :: lupri
      WRITE(lupri,*)'matrixmembuf Printing Routine:'
      IF(associated(matmembuf%fileliststart))THEN
         WRITE(lupri,*)'matrixmembuf Files'
         call print_FileUnit(matmembuf%fileliststart,lupri)
      ELSE
         WRITE(lupri,*)'No files allocated int matrixmembuf'
      ENDIF
    end subroutine matrixmembuf_print
    recursive subroutine print_fileUnit(fileitem,lupri)
      implicit none
      integer :: lupri
      type(matrixfiletype) :: fileitem
      !
      integer :: number
      WRITE(lupri,*)'the Filename:',fileitem%filename
      WRITE(lupri,*)'the iunit   :',fileitem%iunit
      IF(associated(fileitem%matrixliststart))THEN
         number = 0
         call print_filematrix(fileitem%matrixliststart,lupri,number,fileitem%filename)
      ELSE
         WRITE(lupri,*)'No Matrices written to this file'
      ENDIF
      IF(associated(fileitem%filenext))THEN
         call print_fileUnit(fileitem%filenext,lupri)
      ENDIF
    end subroutine print_fileUnit
    recursive subroutine print_fileMatrix(matitem,lupri,number,filename)
      integer :: lupri,number
      character(len=80) :: filename
      type(matrixfiletype2) :: matitem
      number = number + 1
      WRITE(lupri,*)'the Matrix number ',number,' on file ',filename
      call mat_print(matitem%mat,1,matitem%mat%nrow,1,matitem%mat%ncol,lupri)
      IF(associated(matitem%matnext))THEN
         call print_filematrix(matitem%matnext,lupri,number,filename)
      ENDIF
    end subroutine print_fileMatrix

    !==========================================
    !matrixmembuf_Open
    !==========================================
    !  Open File For writing and reading
    subroutine matrixmembuf_Open(iunit,filename)
      implicit none
      integer :: iunit
      character(len=80) :: filename
      logical :: optionNew2,Found
      IF(iunit.NE.-1)call lsquit('matrixmembuf_Open requires iunit=-1',-1)
      !determine if file is already there
      call matrixmembuf_FindFile(filename,iunit,Found) 
      IF(.NOT.Found)THEN
         !provide unique logical unit number
         call  matrixmembuf_new_iunit(filename,iunit)
         optionNew2 = .TRUE. !new file
      ELSE
         optionNew2 = .FALSE. !old file
      ENDIF
      IF(optionNew2)THEN
         !new file
         IF(associated(matmembuf%fileliststart))THEN
            allocate(MATMEMBUF%filelistend%filenext)
            nullify(MATMEMBUF%filelistend%filenext%filenext)
            MATMEMBUF%filelistend%filenext%iunit = iunit
            MATMEMBUF%filelistend%filenext%filename = filename
            nullify(MATMEMBUF%filelistend%filenext%matrixliststart)
            nullify(MATMEMBUF%filelistend%filenext%matrixlistend)
            nullify(MATMEMBUF%filelistend%filenext%matrixcurrent)
            MATMEMBUF%filelistend => MATMEMBUF%filelistend%filenext
         ELSE
            !first file
            allocate(matmembuf%fileliststart)
            MATMEMBUF%fileliststart%iunit = iunit
            MATMEMBUF%fileliststart%filename = filename
            nullify(MATMEMBUF%fileliststart%matrixliststart)
            nullify(MATMEMBUF%fileliststart%matrixlistend)
            nullify(MATMEMBUF%fileliststart%matrixcurrent)
            MATMEMBUF%filelistend => MATMEMBUF%fileliststart
            nullify(MATMEMBUF%fileliststart%filenext)
         ENDIF
      ELSE
         !old file
         call matrixmembuf_setmatrixcurrent(iunit) 
      ENDIF
    end subroutine matrixmembuf_Open

    !==========================================
    !matrixmembuf_Open
    !==========================================
    !  Open File For writing and reading
    subroutine matrixmembuf_Overwrite(iunit,filename)
      implicit none
      integer :: iunit
      character(len=80) :: filename
      logical :: FOUND
      FOUND=.FALSE.
      call OverwriteIunitFileUnit2(matmembuf%fileliststart,iunit,Found,filename)
    end subroutine Matrixmembuf_Overwrite
    recursive subroutine OverwriteIunitFileUnit2(item,iunit,Found,filename)
      implicit none
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      character(len=80) :: filename
      IF(item%filename.EQ.filename)THEN
         IF(associated(item%matrixliststart))THEN
            call Free_filematrix(item%matrixliststart)
            nullify(item%matrixliststart)
            nullify(item%matrixlistend)
         ENDIF
         FOUND = .TRUE.         
      ELSEIF(associated(item%filenext))THEN
         call OverwriteIunitFileUnit2(item%filenext,iunit,Found,filename)
      ENDIF      
    end subroutine OverwriteIunitFileUnit2

    !==========================================
    !matrixmembuf_Close
    !==========================================
    !  Open File For writing and reading
    subroutine matrixmembuf_Close(iunit,optionDelete)
      implicit none
      integer :: iunit
      character(len=80) :: filename
      logical :: optionDelete,Found
      IF(optionDelete)THEN
         IF(associated(matmembuf%fileliststart))THEN
            call FindIunitAndFree(matmembuf%fileliststart,iunit,Found)
         ELSE
            call lsquit('delete option but no files',-1)
         ENDIF
      ENDIF
    end subroutine matrixmembuf_Close
    recursive subroutine FindIunitAndFree(item,iunit,Found)
      implicit none
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      IF(item%iunit.EQ.iunit)THEN
         Found = .TRUE.
         IF(associated(item%matrixliststart))THEN
            CALL free_matlist(item%matrixliststart)
         ELSE
            call lsquit('no mat list in close delete',-1)
         ENDIF
      ELSE
         call FindIunitAndFree(item%filenext,iunit,Found)
      ENDIF
    end subroutine FindIunitAndFree
    
    !==========================================
    !matrixmembuf_write_to_mem(iunit,A)
    !==========================================
    subroutine matrixmembuf_write_to_mem(iunit,A)
      integer :: iunit
      type(matrix) :: A
      !
      logical :: Found
      Found=.FALSE.
      call FindIunit(iunit,Found)
      IF(.NOT.FOUND)call lsquit('file error in matrixmembuf_write_to_mem',-1)
      IF(.NOT.associated(matmembuf%fileliststart))call lsquit('no files - file error in matrixmembuf_write_to_mem',-1)
      call FindIunitAnd_write_to_mem(matmembuf%fileliststart,iunit,Found,A)
    end subroutine matrixmembuf_write_to_mem
    recursive subroutine FindIunitAnd_write_to_mem(item,iunit,Found,A)
      implicit none
      type(matrix) :: A
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      IF(item%iunit.EQ.iunit)THEN
         Found = .TRUE.
         CALL matrixmembuf_write_to_mem1(item,iunit,A)
      ELSEIF(associated(item%filenext))THEN
         call FindIunitAnd_write_to_mem(item%filenext,iunit,Found,A)
      ENDIF
    end subroutine FindIunitAnd_write_to_mem
    subroutine matrixmembuf_write_to_mem1(fileitem,iunit,A)
      type(matrix) :: A
      integer :: iunit
      type(matrixfiletype) :: fileitem      
      IF(associated(fileitem%matrixliststart))THEN
         allocate(fileitem%matrixlistend%matnext)
         nullify(FILEITEM%matrixlistend%matnext%matnext)
         call mat_init(FILEITEM%matrixlistend%matnext%mat,A%nrow,A%ncol)
         call mat_assign(FILEITEM%matrixlistend%matnext%mat,A)
         FILEITEM%matrixlistend => FILEITEM%matrixlistend%matnext
         FILEITEM%matrixcurrent => FILEITEM%matrixlistend
      ELSE
         !first matrix on file
         allocate(fileitem%matrixliststart)
         call mat_init(FILEITEM%matrixliststart%mat,A%nrow,A%ncol)
         call mat_assign(FILEITEM%matrixliststart%mat,A)
         FILEITEM%matrixlistend => FILEITEM%matrixliststart
         FILEITEM%matrixcurrent => FILEITEM%matrixliststart
         nullify(FILEITEM%matrixliststart%matnext)
      ENDIF
    end subroutine matrixmembuf_write_to_mem1

    !==========================================
    !matrixmembuf_read_from_mem(iunit,A)
    !==========================================
    subroutine matrixmembuf_read_from_mem(iunit,A)
      integer :: iunit
      type(matrix) :: A
      !
      logical :: Found
      Found=.FALSE.
      call FindIunit(iunit,Found)
      IF(.NOT.FOUND)call lsquit('file error in matrixmembuf_read_from_mem',-1)
      IF(.NOT.associated(matmembuf%fileliststart))call lsquit('no files - file error in matrixmembuf_read_from_mem',-1)
      call FindIunitAnd_read_from_mem(matmembuf%fileliststart,iunit,Found,A)
    end subroutine matrixmembuf_read_from_mem
    recursive subroutine FindIunitAnd_read_from_mem(item,iunit,Found,A)
      implicit none
      type(matrix) :: A
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      IF(item%iunit.EQ.iunit)THEN
         Found = .TRUE.
         CALL matrixmembuf_read_from_mem1(item,iunit,A)
      ELSEIF(associated(item%filenext))THEN
         call FindIunitAnd_read_from_mem(item%filenext,iunit,Found,A)
      ENDIF
    end subroutine FindIunitAnd_read_from_mem
    subroutine matrixmembuf_read_from_mem1(fileitem,iunit,A)
      type(matrix) :: A
      integer :: iunit
      type(matrixfiletype) :: fileitem      
      IF(associated(FILEITEM%matrixcurrent))THEN
         call mat_assign(A,FILEITEM%matrixcurrent%mat)
         FILEITEM%matrixcurrent => FILEITEM%matrixcurrent%matnext 
      ENDIF
    end subroutine matrixmembuf_read_from_mem1

    !==========================================
    !matrixmembuf_free(iunit)
    !==========================================
!!$    subroutine matrixmembuf_free()
!!$      IF(associated(matmembuf%fileliststart))THEN
!!$         call free_fileunit(matmembuf%fileliststart)
!!$         nullify(item%fileliststart)
!!$         nullify(item%filelistend)
!!$      ENDIF
!!$    end subroutine matrixmembuf_free
!!$    recursive subroutine Free_fileunit(item)
!!$      implicit none
!!$      type(matrixfiletype) :: item
!!$      IF(associated(item%filenext))THEN
!!$         call Free_fileunit(item%filenext)
!!$         IF(associated(item%matrixliststart))THEN
!!$            call free_matlist(item%matrixliststart)
!!$            nullify(item%matrixliststart)
!!$            nullify(item%matrixlistend)
!!$         ENDIF
!!$      ENDIF
!!$    end subroutine Free_fileunit
    recursive subroutine free_matlist(item)
      type(matrixfiletype2) :: item      
      IF(associated(ITEM%matnext))THEN
         call free_matlist(item%matnext)
         nullify(item%matnext)
      ENDIF
      call mat_free(item%mat)
    end subroutine free_matlist

    subroutine matrixmembuf_FreeFile(filename,iunit)
      integer :: iunit
      character(len=80) :: filename
      logical :: found
      Found = .FALSE.
      call FreeIunit2(iunit,Found,filename)
    end subroutine matrixmembuf_FreeFile
    subroutine FreeIunit2(iunit,Found,filename)
      implicit none
      integer :: iunit
      logical :: Found        
      character(len=80) :: filename
      IF(associated(matmembuf%fileliststart))THEN
         call FreeIunitFileUnit2(matmembuf%fileliststart,iunit,Found,filename)
      ENDIF
    end subroutine FreeIunit2
    recursive subroutine FreeIunitFileUnit2(item,iunit,Found,filename)
      implicit none
      integer :: iunit
      logical :: Found
      type(matrixfiletype) :: item
      character(len=80) :: filename
      IF(item%filename.EQ.filename)THEN
         item%iunit=-1
         item%filename = 'EMPTY                             '
         IF(associated(item%matrixliststart))THEN
            call Free_filematrix(item%matrixliststart)
            nullify(item%matrixliststart)
            nullify(item%matrixlistend)
!            nullify(item%matrixlistcurrent)
         ENDIF
         FOUND = .TRUE.         
      ELSEIF(associated(item%filenext))THEN
         call FreeIunitFileUnit2(item%filenext,iunit,Found,filename)
      ENDIF      
    end subroutine FreeIunitFileUnit2
    
END MODULE Matrix_Operations

!> \brief Standalone routine for BSM IO support
!> \author P. Salek
!> \date 2003
!> \param iunit ?
!> \param cnt ?
!> \param idata ?
subroutine mat_write_int(iunit,cnt,idata)
   use Matrix_module
   integer, intent(in) :: iunit, cnt
   integer, intent(in) :: idata(cnt)
   write(iunit) idata
end subroutine mat_write_int

!> \brief Standalone routine for BSM IO support
!> \author P. Salek
!> \date 2003
!> \param iunit ?
!> \param cnt ?
!> \param idata ?
subroutine mat_read_int(iunit,cnt,idata)
   use Matrix_module
   integer, intent(in)  :: iunit, cnt
   integer, intent(out) :: idata(cnt)
   read(iunit) idata
end subroutine mat_read_int

!> \brief Standalone routine for BSM IO support
!> \author P. Salek
!> \date 2003
!> \param iunit ?
!> \param cnt ?
!> \param data ?
subroutine mat_write_real(iunit,cnt,data)
   use Matrix_module
   integer,     intent(in) :: iunit, cnt
   real(realk), intent(in) :: data(cnt)
   write(iunit) data
end subroutine mat_write_real

!> \brief Standalone routine for BSM IO support
!> \author P. Salek
!> \date 2003
!> \param iunit ?
!> \param cnt ?
!> \param data ?
subroutine mat_read_real(iunit,cnt,data)
   use Matrix_module
   integer,     intent(in)  :: iunit, cnt
   real(realk), intent(out) :: data(cnt)
   read(iunit) data
end subroutine mat_read_real

!Hack routines - see debug_convert_density in debug.f90
subroutine mat_write_int2(iunit,cnt,idata)
   use Matrix_module
   integer, intent(in) :: iunit, cnt
   integer, intent(in) :: idata(cnt)
   write(iunit,*) idata
end subroutine mat_write_int2

subroutine mat_read_int2(iunit,cnt,idata)
   use Matrix_module
   integer, intent(in)  :: iunit, cnt
   integer, intent(out) :: idata(cnt)
   read(iunit,*) idata
end subroutine mat_read_int2

subroutine mat_write_real2(iunit,cnt,data)
   use Matrix_module
   integer,     intent(in) :: iunit, cnt
   real(realk), intent(in) :: data(cnt)
   write(iunit,*) data
end subroutine mat_write_real2

subroutine mat_read_real2(iunit,cnt,data)
   use Matrix_module
   integer,     intent(in)  :: iunit, cnt
   real(realk), intent(out) :: data(cnt)
   read(iunit,*) data
end subroutine mat_read_real2
!End hack routines

#ifdef VAR_LSMPI
      !> \brief Pass matrix_type to other MPI nodes
      !> \author T. Kjaergaard
      !> \date 2011
      !> \param a the matrix type
      subroutine lsmpi_set_matrix_type_master(a)
  use infpar_module
  use lsmpi_type
        implicit none
        integer,intent(in) :: a
        call ls_mpibcast(a,infpar%master,MPI_COMM_LSDALTON)
      end subroutine lsmpi_set_matrix_type_master

      !> \brief obtains the matrix_type from master MPI nodes
      !> \author T. Kjaergaard
      !> \date 2011
      !> \param the matrix type
      subroutine lsmpi_set_matrix_type_slave()
  use matrix_operations
  use infpar_module
  use lsmpi_type
        implicit none
        integer :: a
        call ls_mpibcast(a,infpar%master,MPI_COMM_LSDALTON)

        call mat_select_type(a,6)

      end subroutine lsmpi_set_matrix_type_slave
#endif