
subroutine pdm_array_slave()
  use precision
  !use matrix_operations_scalapack, only: BLOCK_SIZE, SLGrid, DLEN_
  use memory_handling, only: mem_alloc,mem_dealloc
  use matrix_operations, only: mtype_scalapack, matrix_type
  use dec_typedef_module
#ifdef VAR_LSMPI
  use infpar_module
  use lsmpi_type
#endif

  use tensor_interface_module

   IMPLICIT NONE
   TYPE(array) :: A, B, C, D, AUX
   CHARACTER    :: T(2)
   INTEGER      :: JOB, i, j
   !INTEGER      :: DESC_A(DLEN_), DESC_B(DLEN_), DESC_C(DLEN_), DESC_AF(DLEN_),dist(2)
   real(REALK)  :: AF, AB(2)
   real(REALK),pointer :: dummy(:)
   integer, pointer    :: idiag(:)
   logical :: logi
   integer, external :: numroc
   integer, pointer :: dims(:),dims2(:)
#ifdef VAR_LSMPI
   CALL PDM_ARRAY_SYNC(JOB,A,B,C,D) !Job is output
   !print *,"slave in pdm-> job is",JOB
   !print *,"array1_dims",A%dims
   !print *,"array2_dims",B%dims
   !print *,"array3_dims",C%dims

   SELECT CASE(JOB)
     CASE(JOB_INIT_ARR_TILED)
       call mem_alloc(idiag,A%mode)
       call mem_alloc(dims,A%mode)
       idiag=A%tdim
       dims =A%dims
       call arr_free_aux(A)
       A=array_init_tiled(dims,A%mode,MASTER_INIT,idiag,A%zeros) 
       call mem_dealloc(idiag)
       call mem_dealloc(dims)
     CASE(JOB_FREE_ARR_PDM)
       call array_free_pdm(A) 
     CASE(JOB_INIT_ARR_REPLICATED)
       call mem_alloc(dims,A%mode)
       dims =A%dims
       call arr_free_aux(A)
       A=array_init_replicated(dims,A%mode,MASTER_INIT) 
       call mem_dealloc(dims)
     CASE(JOB_PRINT_MEM_INFO1)
       call print_mem_per_node(DECinfo%output,.false.)
     CASE(JOB_PRINT_MEM_INFO2)
       call mem_alloc(dummy,1)
       call print_mem_per_node(DECinfo%output,.false.,dummy)
       call mem_dealloc(dummy)
     CASE(JOB_GET_NRM2_TILED)
       AF=array_tiled_pdm_get_nrm2(A)
     CASE(JOB_DATA2TILED_DIST)
       !dummy has to be allocated, otherwise seg faults might occur with 
       !some compilers
       call mem_alloc(dummy,1)
       !call cp_data2tiled(A,dummy,A%dims,A%mode,.true.)
       print *,"not necessary"
       call mem_dealloc(dummy)
     CASE(JOB_GET_TILE_SEND)
       !i,dummy and j are just dummy arguments
       call array_get_tile(A,i,dummy,j)
     CASE(JOB_PRINT_TI_NRM)
       call array_tiled_pdm_print_ti_nrm(A,0)
     CASE(JOB_SYNC_REPLICATED)
       call array_sync_replicated(A)
     CASE(JOB_GET_NORM_REPLICATED)
       AF=array_print_norm_repl(A)
     CASE(JOB_PREC_DOUBLES_PAR)
       call precondition_doubles_parallel(A,B,C,D)
     CASE(JOB_DDOT_PAR)
       AF=array_ddot_par(A,B,0)
     CASE(JOB_ADD_PAR)
       call array_add_par(A,AF,B)
     CASE(JOB_CP_ARR)
       call array_cp_tiled(A,B)
     CASE(JOB_ARRAY_ZERO)
       call array_zero_tiled_dist(A)
     CASE(JOB_GET_CC_ENERGY)
       AF = get_cc_energy_parallel(A,B,C)
     CASE(JOB_GET_FRAG_CC_ENERGY)
       !the counterpart to this buffer is in get_fragment_cc_energy
       call ls_mpiinitbuffer(infpar%master,LSMPIBROADCAST,infpar%lg_comm)
       call ls_mpi_buffer(i,infpar%master)
       call mem_alloc(dims,i)
       call ls_mpi_buffer(dims,i,infpar%master)
       call ls_mpi_buffer(j,infpar%master)
       call mem_alloc(dims2,j)
       call ls_mpi_buffer(dims2,j,infpar%master)
       call ls_mpifinalizebuffer(infpar%master,LSMPIBROADCAST,infpar%lg_comm)

       AF = get_fragment_cc_energy_parallel(A,B,C,i,j,dims,dims2)

       call mem_dealloc(dims)
       call mem_dealloc(dims2)
     CASE(JOB_CHANGE_INIT_TYPE)
       call change_init_type_td(A,i)
   END SELECT
#endif
end subroutine pdm_array_slave