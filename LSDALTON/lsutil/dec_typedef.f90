!> @file
!> The module contains structures used in DEC
!> \author Kasper Kristensen

!> The module contains structures used in DEC (and printing routines)
module dec_typedef_module

  use precision
  use,intrinsic :: iso_c_binding, only:c_ptr
  use TYPEDEFTYPE, only: lsitem
  use Matrix_module, only: matrix

  ! IMPORTANT: Number of possible energies to calculate using the DEC scheme
  ! MUST BE UPDATED EVERYTIME SOMEONE ADDS A NEW MODEL TO THE DEC SCHEME!!!!
  ! MODIFY FOR NEW MODEL
  ! MODIFY FOR NEW CORRECTION
  integer, parameter :: ndecenergies = 13

  !> \author Kasper Kristensen
  !> \date June 2010
  !> \brief Contains settings for DEC calculation
  type DECsettings

     !> Run DEC calculation
     logical :: doDEC
     !> Do Hartree-Fock calculation before DEC calculation (default: TRUE)
     logical :: doHF
     !> Memory available for DEC calculation
     real(realk) :: memory
     !> Memory defined by input? (If not, use system call).
     logical :: memory_defined
     !> Frozen core calculation?
     logical :: frozencore
     !> Book keeping of the number of DEC calculations for each FOT level
     !> (only relevant for geometry optimizations)
     integer,dimension(8) :: ncalc

     ! -- Type of calculation
     !> Full molecular job
     logical :: full_molecular_cc ! full molecular cc
     !> Full calculation where individual pair and single energies are calculated in ONE energy calc.
     logical :: FullDEC
     !> Simulate full molecular calculation in DEC mode
     logical :: simulate_full
     !> How many atoms to use in simulation mode
     integer :: simulate_natoms
     !> Skip the read-in of molecular info files dens.restart, fock.restart, lcm_orbitals.u (for testing)
     logical :: SkipReadIn
     !> For CC2 and CCSD: Include polarization effect from singles in full molecule
     logical :: SinglesPolari
     !> Relative difference between singles amplitudes to accept
     !> without invoking an additional set of fragment calculations
     real(realk) :: singlesthr
     !> Split total fragment calculation into this number of subfragments
     integer :: nsubfrag
     !> Number of subfragments for second fragment if pair calculation
     integer :: nsubfrag2
     !> Use subfragment scheme
     logical :: subfrag
     !> DEC files (lcm_orbitals.u, fock.restart, dens.restart, overlapmatrix, DECorbitals.info) 
     !> are in 64 bit integers but the program was compiled with 32 bit integers so these
     !> files need to be converted during the read-in.
     logical :: convert64to32
     logical :: convert32to64
     !> Restart calculation if some of the fragments were calculated in a previous calculation
     logical :: restart
     !> Creating files for restart: Time (in seconds) passing before backing up restart files
     real(realk) :: TimeBackup
     !> Read DEC orbital file DECOrbitals.info from file (default: Existing file is overwritten)
     logical :: read_dec_orbitals
     ! --

     ! -- Debug modes
     !> Debug fragmentation module
     logical :: fragmentation_debug
     !> Debug DEC driver
     logical :: dec_driver_debug
     !> Debug CC driver
     logical :: cc_driver_debug
     !> Debug patricks test
     logical :: ccsd_old, manual_batchsizes
     logical :: solver_par
     integer :: ccsdAbatch,ccsdGbatch
     !> General HACK parameter, to be used for easy debugging
     logical :: hack
     logical :: hack2
     !> Debug prints for DEC MPI parallelization
     logical :: mpidebug
     !> Factor determining whether MPI groups should split
     integer :: mpisplit
     !\> forcing ome or the other scheme in get_coubles residual integral_driven
     logical :: force_scheme,dyn_load
     integer :: en_mem
     !\> test the array structure
     logical :: array_test
     !\> test the array reorderings
     logical :: reorder_test
     !> save next guess amplitudes of CCSD in each iteration on disk
     logical :: CCSDsaferun
     !> skip reading the old amplitudes from disk
     logical :: CCSDno_restart
     ! --

     ! -- Output options 
     !> File unit for LSDALTON.OUT
     integer :: output
     ! --

     ! -- Orbital
     !> Simple Mulliken charge threshold
     real(realk) :: mulliken_threshold
     !> Simple Mulliken charge criteria 
     logical :: simple_mulliken_threshold
     !> Norm error in approximated (fitted orbitals)
     real(realk) :: approximated_norm_threshold
     !> Check that LCM orbitals are correct
     logical :: check_lcm_orbitals
     !> Use canonical orbitals
     logical :: use_canonical
     !> Assign orbitals also to H atoms (default: do not assign to H)
     logical :: reassignHatoms
     !> Use Mulliken population analysis to assign orbitals (default: Lowdin)
     logical :: mulliken
     !> Use Boughton-Pulay criteria for generating orbitals rather than simple Lowdin charge criteria
     logical :: BoughtonPulay
     !> Fit orbital coefficients in fragment (default: true)
     logical :: FitOrbitals
     !> Threshold for simple Lowdin procedure for determining atomic extent
     real(realk) :: simple_orbital_threshold
     !> Has simple orbital threshold been defined manually in input (true),
     !> or should simple orbital threshold be adapted to FOT 
     !> as descripted under FOTlevel (false)?
     logical :: simple_orbital_threshold_set     
     ! --

     ! -- Fragment
     !> Max iterations for expanding fragment
     integer :: MaxIter
     !> FOT level defining precision of calculation, see set_input_for_fot_level
     integer :: FOTlevel
     !> Max accepted FOT level
     integer :: maxFOTlevel

     !> Fragment optimization threshold
     real(realk) :: FOT
     !> Print level for CC driver in fragment mode
     integer :: PL
     !> Dont dispatch CC jobs for fragments
     logical :: SkipCC
     !> Purify fitted MO coefficients (projection + orthogonalization)
     logical :: PurifyMOs
     !> Use full molecular Fock matrix to precondition
     logical :: precondition_with_full
     !> Includes the whole molecule in all fragments
     logical :: InclFullMolecule
     !> Use occupied/virtual hybrid partitioning scheme
     !> This is a subset of the Lagrangian scheme. It contains an equal balance
     !> between the occupied and virtual orbital spaces (as in the Lagrangian scheme), 
     !> but does not use the multiplier terms of the Lagrangian.
     !> Main use: CCSD
     logical :: HybridScheme

     !> Number of atoms to include in fragment expansion
     integer :: LagStepSize
     !> Step size (no. atoms) in atomic extent optimization
     integer :: AEstep
     !> Use fragment-adapted orbitals for fragment calculations
     logical :: FragAdapt
     !> for ccsd(t) calculations, option to use MP2 optimized fragments
     !KK fixme: Currently DEC-CCSD(T) ONLY works when use_mp2_frag=.true.!
     logical :: use_mp2_frag
     ! --  

     ! -- Pair fragments
     !> Distance cutoff for pair fragments
     real(realk) :: pair_distance_threshold
     !> Pair cutoff set manually (will overwrite default pair cutoff defined by FOTlevel)
     logical :: paircut_set
     !> Pair distance beyond which reduced fragments are used
     real(realk) :: PairReductionDistance
     !> When pair regression fit is performed, pair distances smaller than PairMinDist are ignored
     real(realk) :: PairMinDist
     !> Skip pair analysis (only for debugging)
     logical :: NoExtraPairs
     ! --

     ! -- Independent calculation of fragments and pairs
     !> Atom to optimize in single fragment job
     integer :: fragment_to_do 
     !> Atom A to construct atomic pair fragment in single pair job
     integer :: fragment_a_to_pair 
     !> Atom B to construct atomic pair fragment in single pair job
     integer :: fragment_b_to_pair 
     ! --

     ! Memory use for full molecule structure
     real(realk) :: fullmolecule_memory

     ! -- CC solver options
     !> Use devel version of doubles
     logical :: ccsd_expl
     !> Label to print CC models
     character(len=8), dimension(10) :: cc_models
     !> Restart T2 (obsolete for the moment)
     logical :: t2_restart
     !> Simulate full ERI using RI arrays (obsolete for the moment)
     logical :: simulate_eri
     !> Construct Fock matrix from RI integrals (obsolete for the moment)
     logical :: fock_with_ri
     !> Max number of iterations in CC driver
     integer :: ccMaxIter
     !> Max number of vectors in the subspace
     integer :: ccMaxDIIS
     !> Requested CC model
     integer :: ccModel ! 1 - MP2, 2 - CC2, 3 - CCSD, 4 - CCSD(T), 5 - RPA
     !> Use F12 correction
     logical :: F12
     !> CC convergence threshold
     real(realk) :: ccConvergenceThreshold
     !> Was CC convergence threshold specified?
     logical :: CCthrSpecified
     !> Use singles
     logical :: use_singles
     !> Use preconditioner
     logical :: use_preconditioner
     !> Use preconditioner in B matrix
     logical :: use_preconditioner_in_b
     !> Use CROP (if false we use DIIS)
     logical :: use_crop
     !> Show old timings
     logical :: show_time
     !> Show new timings
     logical :: timing
     !> Show memory
     logical :: show_memory
     !> Skip full ao matrix
     logical :: skip_full_ao
     !> Save array4 on file instead of in memory
     logical :: array4OnFile
     logical :: array4OnFile_specified
     !> AO-based CC (not in use now)
     logical :: AObasedCC

     ! -- Arrays
     !> Zero threshold for stored data (not used yet)
     real(realk) :: zero_threshold
     ! --

     ! -- Timings
     real(realk) :: integral_time_cpu
     real(realk) :: integral_time_wall
     real(realk) :: MOintegral_time_cpu
     real(realk) :: MOintegral_time_wall
     real(realk) :: solver_time_cpu
     real(realk) :: solver_time_wall
     real(realk) :: energy_time_cpu
     real(realk) :: energy_time_wall
     real(realk) :: density_time_cpu
     real(realk) :: density_time_wall
     real(realk) :: gradient_time_cpu
     real(realk) :: gradient_time_wall
     real(realk) :: trans_time_cpu
     real(realk) :: trans_time_wall
     real(realk) :: reorder_time_cpu
     real(realk) :: reorder_time_wall
     ! Time for memory allocation AND deallocation
     real(realk) :: memallo_time_cpu  
     real(realk) :: memallo_time_wall


     ! MPI information
     integer(kind=ls_mpik) :: MPIgroupsize


     ! First order properties
     ! *********************

     !> Do first order properties (MP2 density, electric dipole, mp2 gradient)
     logical :: first_order

     !> MP2 density matrix
     logical :: MP2density    ! Calculate fragment contributions to MP2 density
     logical :: SkipFull ! only do fragment part of density or gradient (mostly for debugging)

     ! -- MP2 gradient
     !> Calculate MP2 gradient
     logical :: gradient
     !> Use preconditioner for kappa multiplier equation
     logical :: kappa_use_preconditioner
     !> Use preconditioner for kappa multiplier equation
     logical :: kappa_use_preconditioner_in_b
     !> Number of vector to save in kappa multiplier equation
     integer :: kappaMaxDIIS
     !> Maximum number of iteration in kappa multiplier equation
     integer :: kappaMaxIter
     !> Debug print in kappa multiplier equation
     logical :: kappa_driver_debug
     !> Residual threshold for kappa orbital rotation multiplier equation
     real(realk) :: kappaTHR
     !> Factor multiply intrinsic energy error by before returning error to geometry optimizer
     real(realk) :: EerrFactor
     !> Old energy error (used only for geometry opt)
     real(realk) :: EerrOLD

     ! Save fragment files (default: do not save)
     logical :: SaveFragFile

  end type DECSETTINGS


  !tile structure
  type tile
    type(c_ptr) :: c
    real(realk),pointer :: t(:) => null()         !data in tiles
    integer,pointer :: d(:)     => null()         !actual dimension of the tiles
    integer :: e,gt                               !number of elements in current tile, global ti nr
  end type tile
  type scalapack_block_info
    integer,pointer :: fe(:)  => null()            !first element in row/column blocks(rowidx:first element,colidx:node), length of row/column batches (rowidx:length,colidx:node)
    integer,pointer :: lb(:)  => null()
    integer,pointer :: bpn(:) => null()    !blocks per node, leading dimension of distributed matrix on node, indices as above
    integer,pointer :: ldn(:) => null()
    integer :: mld,mnb,mnbpn            !maximum leading dimension and maximum number of batches (per node) define the size of some matrices and thus index restrictions
  endtype scalapack_block_info


  type array
     !mode=number of modes of the array or order of the corresponding tensor,
     !nelms=number of elements in the array
     !atype= format or distribution in which the array is stored --> dense, distributed --> see parameters in array_operations.f90
     integer :: mode,nelms
     integer :: atype
     !> Dimensions
     integer, pointer :: dims(:)     => null ()
     !> Data, only allocate the first for the elements and use the others just
     !to reference the data in the first pointer
     real(realk), pointer :: elm1(:) => null()
     ! the following should just point to elm1
     real(realk), pointer :: elm2(:,:) => null()
     real(realk), pointer :: elm3(:,:,:) => null()
     real(realk), pointer :: elm4(:,:,:,:) => null()
     real(realk), pointer :: elm5(:,:,:,:,:) => null()
     real(realk), pointer :: elm6(:,:,:,:,:,:) => null()
     real(realk), pointer :: elm7(:,:,:,:,:,:,:) => null()


     !in order to have only one array type the tile information is always there
     type(c_ptr)        :: dummyc
     real(realk),pointer:: dummy(:)  => null()       !for the creation of mpi windows a dummy is required
     type(tile),pointer :: ti(:)     => null()       !tiles, if matrix should be distributed
     integer(kind=ls_mpik),pointer    :: wi(:)     => null()       !windows for tiles, if matrix should be distributed, there are ntiles windows to be inited
     integer,pointer    :: ntpm(:)   => null()       !dimensions in the modes, number of tiles per mode, 
     integer,pointer    :: tdim(:)   => null()       !dimension of the tiles per mode(per def symmetric, but needed)
     integer,pointer    :: addr_p_arr(:)   => null() !address of array in persistent array "p_arr" on each node
     !global tile information
     integer :: ntiles,tsize                         !batching of tiles in one mode, number of tiles, tilesize (ts^mode), amount of modes of the array
     integer :: nlti                                 !number of local tiles
     integer :: offset                               !use offset in nodes for the distribution of arrays
     integer :: init_type                            !type of initializtation
     logical :: zeros=.false.                        !use zeros in tiles --> it is at the moment not recommended to use .true. here

!#ifdef VAR_SCALAPACK
!     !> PE add PDM for 4idx arrays
!     ! when using parallel distributed memory the following parameter defines uniquely
!     ! the distribution of the array, but there are restrictions on the distribution
!     ! of the 4 idx quantities since only 2D cyclic distribution makes sense with the
!     ! scalapack routines. The integers at different postions have special meanings
!     ! read it in the following way [row node that contains fist element of array, how many dimensions are spread over rows, column node that contains first element of array, how many dimensions are spread over cols]
!     ! or [ frn , rdim , fcn , cdim ]
!     ! so if both rdim and cdim /= 0 then obligatory rdim+cdim=4
!     ! to account for load balancing  
!     integer, pointer :: distribution(:) => null()
!     ! the array4 parts on the nodes are allocated in the DARRAY which was implemented
!     ! for the matrix type but has general functionality, to identify the parts, the
!     ! address is saved for the nodes rows and cols on master in addr_on_grid
!     integer,pointer :: addr_on_grid(:,:) => null()
!     integer :: localnrow,localncol,nrow,ncol,grid_nr
!     type(scalapack_block_info) :: block(2)  !1=row block info , 2=col block info
!#endif

     !Dragging along all the old array4 stuff to stay compatible
     integer :: FUnit
     character(len=80) :: FileName
     integer(kind=long) :: address_counter
     integer :: storing_type
     integer(kind=long) :: nelements
     integer(kind=long), pointer :: address(:,:,:,:) => null()

  end type array

  type array2

     integer, dimension(2) :: dims
     real(realk), pointer :: val(:,:) => null()

  end type array2

  type array3

     !> Dimensions
     integer, dimension(3) :: dims
     !> Current order
     integer, dimension(3) :: order
     !> Data
     real(realk), pointer :: val(:,:,:) => null()

  end type array3

  type array4

     !> Dimensions
     integer, dimension(4) :: dims
     !> Current order
     integer, dimension(4) :: order
     !> Data
     real(realk), pointer :: val(:,:,:,:) => null()
     !> File unit counter
     integer :: FUnit
     !> File name
     character(len=80) :: FileName

     ! Information only used when array4s are stored on file (array4OnFile= .true.)
     ! ****************************************************************************

     !> Address counter
     integer(kind=long) :: address_counter

     !> Storing type
     integer :: storing_type
     ! Storing_type = 2: The values are stored on file as: val(:,:,n1,n2)
     ! Storing_type = 3: The values are stored on file as: val(:,n1,n2,n3)


     !> Number of elements stored in each address on file
     integer(kind=long) :: nelements
     ! For storing_type=2, nelements=dims(1)*dims(2)
     ! For storing_type=3, nelements=dims(1)

     !> List of addresses for the values stored on file
     ! E.g. If one uses storing_type=2 and wants to read in the values
     ! val(:,:,n1,n2), then the corresponding address on file is given by
     ! address(1,1,n1,n2)
     ! where it is understood that all elements are read in for the first two elements
     ! because storing_type=2.
     ! (address is a 4-dimensional array to keep it general and extendable to other cases)
     integer(kind=long), pointer :: address(:,:,:,:) => null()


  end type array4


  type ccorbital

     !> Number of the orbital in full molecular basis
     integer :: orbitalnumber
     !> Cental atom in the population
     integer :: centralatom
     !> Number of significant atoms
     integer :: numberofatoms

     !> List of significant atoms
     integer, pointer :: atoms(:) => null()

  end type ccorbital


  !> Three dimensional array
  type ri

     !> Dimensions
     integer, dimension(3) :: dims
     !> Data
     real(realk), pointer :: val(:,:,:) => null()
     !> File unit
     integer :: FUnit
     !> File name
     character(len=80) :: FileName

  end type ri



  !> All information about full molecule and HF calculation
  type fullmolecule

     !> Number of electrons
     integer :: nelectrons
     !> Number of atoms
     integer :: natoms
     !> Number of basis functions
     integer :: nbasis
     !> Number of auxiliary basis functions
     integer :: nauxbasis
     !> Number of occupied orbitals (core + valence)
     integer :: numocc
     !> Number of core orbitals
     integer :: ncore
     !> Number of valence orbitals (numocc-ncore)
     integer :: nval
     !> Number of unoccupied orbitals
     integer :: numvirt


     !> Number of basis functions on atoms
     integer, pointer :: atom_size(:) => null()
     !> Index of the first basis function for an atom
     integer, pointer :: atom_start(:) => null()
     !> Index of the last basis function for an atom
     integer, pointer :: atom_end(:) => null()

     !> Occupied MO coefficients (mu,i)
     real(realk), pointer :: ypo(:,:) => null()
     !> Virtual MO coefficients (mu,a)
     real(realk), pointer :: ypv(:,:) => null()

     !> Fock matrix (AO basis)
     real(realk), pointer :: fock(:,:) => null()
     !> Overlap matrix (AO basis)
     real(realk), pointer :: overlap(:,:) => null()

     !> Occ-occ block of Fock matrix in MO basis
     real(realk), pointer :: ppfock(:,:) => null()
     !> Virt-virt block of Fock matrix in MO basis
     real(realk), pointer :: qqfock(:,:) => null()

  end type fullmolecule


  !> Atomic fragment / Atomic pair fragment
  type ccatom

     !> Number of atom in full molecule
     integer :: atomic_number=0
     !> Number of occupied EOS orbitals 
     integer :: noccEOS=0
     !> Number of unoccupied EOS orbitals 
     integer :: nunoccEOS=0
     !> Number of occupied AOS orbitals (for frozen core approx this is only the valence orbitals)
     integer :: noccAOS=0
     !> Number of core orbitals in AOS
     integer :: ncore=0
     !> Total number of orbitals (core+valence) in AOS (noccAOS + ncore)
     integer :: nocctot=0
     !> Total number of unoccupied orbitals (AOS)
     integer :: nunoccAOS=0

     !> Pair fragment?
     logical :: pairfrag

     !> Occupied orbital EOS indices 
     integer, pointer :: occEOSidx(:) => null()
     !> Unoccupied orbital EOS indices 
     integer, pointer :: unoccEOSidx(:) => null()
     !> Occupied AOS orbital indices (only valence orbitals for frozen core approx)
     integer, pointer :: occAOSidx(:) => null()
     !> Unoccupied AOS orbital indices 
     integer, pointer :: unoccAOSidx(:) => null()
     !> Core orbitals indices (only used for frozen core approx, 
     !> otherwise there are included in the occAOSidx list).
     integer,pointer :: coreidx(:) => null()


     ! Special info for reduced fragment of lower accuracy
     !****************************************************
     !> Number of occupied AOS orbitals 
     integer :: REDnoccAOS=0
     !> Total number of unoccupied orbitals (AOS)
     integer :: REDnunoccAOS=0
     !> Occupied orbital indices (AOS) for reduced fragment
     integer, pointer :: REDoccAOSidx(:) => null()
     !> All unoccupied orbital indices (AOS)
     integer, pointer :: REDunoccAOSidx(:) => null()

     !> Indices of occupied EOS in AOS basis
     integer, pointer :: idxo(:) => null()
     !> Indices of unoccupied EOS in AOS basis
     integer, pointer :: idxu(:) => null()

     ! MODIFY FOR NEW MODEL
     ! MODIFY FOR NEW CORRECTION
     !> DEC fragment energies stored in the following manner:
     !> 1. MP2 Lagrangian partitioning scheme
     !> 2. MP2 occupied partitioning scheme
     !> 3. MP2 virtual partitioning scheme
     !> 4. CC2 occupied partitioning scheme
     !> 5. CC2 virtual partitioning scheme
     !> 6. CCSD occupied partitioning scheme
     !> 7. CCSD virtual partitioning scheme
     !> 8. (T) contribution, occupied partitioning scheme
     !> 9. (T) contribution, virtual partitioning scheme
     !> 10. Fourth order (T) contribution, occupied partitioning scheme
     !> 11. Fourth order (T) contribution, virtual partitioning scheme
     !> 12. Fifth order (T) contribution, occupied partitioning scheme
     !> 13. Fifth order (T) contribution, virtual partitioning scheme
     real(realk),dimension(ndecenergies) :: energies
     ! Note 1: Only the energies requested for the model in question are calculated!
     ! Note 2: Obviously you need to change the the global integer "ndecenergies"
     !         at the top of this file if you add new models!!!


     !> The energy definitions below are only used for fragment optimization (FOP)
     !> These are (in general) identical to the corresponding energies saved in "energies".
     !> However, for fragment optimization it is very convenient to have direct access to the energies
     !> without thinking about which CC model we are using...
     !> Energy using occupied partitioning scheme
     real(realk) :: EoccFOP
     !> Energy using virtual partitioning scheme
     real(realk) :: EvirtFOP
     !> Lagrangian energy 
     !> ( = 0.5*OccEnergy + 0.5*VirtEnergy for models where Lagrangian has not been implemented)
     real(realk) :: LagFOP
  
     !> Contributions to the fragment Lagrangian energy from each individual
     !  occupied or virtual orbital.
     real(realk),pointer :: OccContribs(:) => null()
     real(realk),pointer :: VirtContribs(:) => null()

     !> Number of EOS atoms (1 for atomic fragment, 2 for pair fragment)
     integer :: nEOSatoms
     !> List of EOS atoms
     integer, pointer :: EOSatoms(:) => null()


     !> Information used only when the ccatom is a pair fragment
     !> ********************************************************
     !> Atomic number of second atom (first atom is atom_number)
     integer :: atomic_number2
     !> Distance between single fragments used to generate pair
     real(realk) :: pairdist

     !> Total occupied orbital space (orbital type)
     type(ccorbital), pointer :: occAOSorb(:) => null()
     !> Total unoccupied orbital space (orbital type)
     type(ccorbital), pointer :: unoccAOSorb(:) => null()

     !> Number of atoms (atomic extent)
     integer :: number_atoms=0
     !> Number of basis functions
     integer :: number_basis=0
     !> Atomic indices
     integer, pointer :: atoms_idx(:) => null()
     !> Corresponding basis function indices
     integer,pointer :: basis_idx(:) => null()

     !> Has the information inside the expensive box below been initialized or not?
     logical :: BasisInfoIsSet

     ! ===========================================================================
     !                       IMPORTANT: EXPENSIVE BOX
     ! ===========================================================================
     ! The information inside this "expensive box" is what takes the time when a
     ! fragment is initialized (MO coefficients, integral input etc.)
     ! When the fragment is initialized using atomic_fragment_init_orbital_specific
     ! with DoBasis=.false. then this information is NOT SET!
     ! In this way the basic fragment information (everything ouside the expensive box)
     ! can be obtained in a very cheap manner, which is convenient for
     ! planning of a large number of fragment calculations.
     ! ---------------------------------------------------------------------------

     !> AO overlap matrix for fragment
     real(realk),pointer :: S(:,:) => null()

     !> Occupied MO coefficients (only valence space for frozen core approx)
     real(realk), pointer :: ypo(:,:) => null()
     !> Virtual MO coefficients
     real(realk), pointer :: ypv(:,:) => null()
     !> Core MO coefficients
     real(realk),pointer :: CoreMO(:,:) => null()

     !> AO Fock matrix
     real(realk), pointer :: fock(:,:) => null()
     !> Occ-occ block of Fock matrix in MO basis  (only valence space for frozen core approx)
     real(realk), pointer :: ppfock(:,:) => null()
     !> Virt-virt block of Fock matrix in MO basis
     real(realk), pointer :: qqfock(:,:) => null()
     !> Core-core block of Fock matrix in MO basis  (subset of ppfock when frozen core is NOT used)
     real(realk), pointer :: ccfock(:,:) => null()

     !> Integral program input
     type(lsitem) :: mylsitem

     ! End of EXPENSIVE BOX
     ! ==============================================================

     
     ! Information used for fragment-adapted orbitals
     ! *******************************************
     !> Correlation density matrices in local AOS basis
     real(realk), pointer :: OccMat(:,:) => null()  ! occ AOS-EOS
     real(realk), pointer :: VirtMat(:,:) => null()  ! virt AOS-EOS
     !> Threshold to use for throwing away fragment-adapted occupied (1) or virtual (2) orbitals
     real(realk) :: RejectThr(2)
     !> Control of whether corr dens matrices have been set (true) or simply initialized (false)
     logical :: CDset
     !> Is this a fragment-adapted fragment?
     logical :: fragmentadapted
     !> Number of occ orbitals for fragment-adapted orbitals 
     integer :: noccFA
     !> Number of unocc orbitals for fragment-adapted orbitals 
     integer :: nunoccFA
     !> Transformation between AO basis and fragment-adapted basis
     !> Index 1: Local,   Index 2: Fragment-adapted
     !> Has transformation matrices been set (not done by default fragment initialization).
     logical :: FATransSet
     real(realk),pointer :: CoccFA(:,:) => null()     ! dimension: number_basis,noccFA
     real(realk),pointer :: CunoccFA(:,:) => null()   ! dimension: number_basis,nunoccFA


     !> Information used only for the CC2 and CCSD models to describe
     !> long-range effects described by singles amplitudes properly.
     !> *************************************************************
     !> Are t1 amplitudes stored in the fragment structure?
     logical :: t1_stored
     !> Dimensions of t1 amplitudes (virtual,occupied - can be either EOS or AOS)
     integer,dimension(2) :: t1dims
     !> t1 amplitudes
     real(realk),pointer :: t1(:,:) => null()
     !> Indices for occupied fragment indices in full list of orbitals
     integer,pointer :: t1_occidx(:) => null()
     !> Indices for virtual fragment indices in full list of orbitals
     integer,pointer :: t1_virtidx(:) => null()


     ! FLOP ACCOUNTING
     ! ***************
     ! MPI: Sum of flop counts for local slaves (NOT local master, only local slaves!)
     real(realk) :: flops_slaves
     ! Number of integral tasks
     integer :: ntasks

     ! INTEGRAL TIME ACCOUNTING
     ! ************************
     ! MPI: Time(s) used by local slaves
     real(realk) :: slavetime


  end type ccatom


  !> MP2 gradient matrices for full molecule.
  !> \author Kasper Kristensen
  !> \date October 2010
  type FullMP2grad
     !> Number of occupied orbitals in full molecule
     integer :: nocc
     !> Number of virtual orbitals in full molecule
     integer :: nvirt
     !> Number of basis functions in full molecule
     integer :: nbasis
     !> Number of atoms in full molecule
     integer :: natoms
     !> Hartree-Fock energy
     real(realk) :: EHF
     !> MP2 correlation energy
     real(realk) :: Ecorr
     !> Total MP2 energy: EHF + Ecorr
     real(realk) :: Etot
     !> MP2 correlation density matrix in AO basis (see type mp2dens)
     ! (before kappa-bar equation is solved we only have the occ-occ and virt-virt blocks,
     ! corresponding to the unrelaxed correlation density matrix)
     real(realk),pointer :: rho(:,:)
     !> Phi matrix in AO basis.
     real(realk),pointer :: Phi(:,:)
     !> In MO basis Phi is:
     !> Phivv_{ab} = sum_{cij} Theta_{cjai} (cj|bi)
     !> Phivo_{ab} = sum_{cij} Theta_{cjai} (cj|ki)
     !> Phioo_{ij} = sum_{abk} Theta_{bkai} (bk|aj)
     !> Phiov_{ic} = sum_{abk} Theta_{bkai} (bk|ac)

     !> Ltheta = sum_{aibj} Theta_{aibj} (ai|bj)^x
     real(realk),pointer :: Ltheta(:,:) 
     !> Total MP2 molecular gradient
     real(realk),pointer :: mp2gradient(:,:)
  end type FullMP2grad





  !> MP2 density matrix information for a given atomic fragment or pair fragment
  type mp2dens


     ! ************************************************************************************
     !                   MP2 correlation density matrix rho in MO basis:                  !
     !                                                                                    !
     !                               rho_{ij} = - X_{ij}                                  !
     !                               rho_{ab} = Y_{ab}                                    !
     !                               rho_{ai} = kappa_{ai}                                !
     !                               rho_{ia} = kappa_{ai}                                !
     !                                                                                    !
     ! ************************************************************************************


     ! X_{ij} = sum_{abk} t_{ki}^{ba} * mult_{kj}^{ba}
     ! Y_{ab} = sum_{cij} t_{ji}^{ca} * mult_{ji}^{cb}
     !
     ! where the multipliers can be determined simply from the amplitudes:
     ! mult_{ij}^{ab} = 4*t_{ij}^{ab} - 2*t_{ij}^{ba}
     !
     ! The determination of the kappa orbital rotation multipliers requires the solution
     ! of the full molecular orbital rotation equation. To determine the RHS matrix
     ! for this equation we need to calculate the virt-occ and occ-virt blocks of
     ! the Phi matrix (using the index convention in cc_ao_contractions):
     ! Phivo_{dl} = sum_{cij} Theta_{ij}^{cd} (ci|jl)
     ! Phiov_{lc} = sum_{abk} Theta_{kl}^{ba} (bk|ac)
     !
     ! The Phi matrix is also constructed based on fragment calculations.
     ! When X,Y,Phivo, and Phiov have been determined, the RHS for the kappa equation is:
     !
     ! RHS_{ai} = Phiov_{ia} - Phivo_{ai} + G_{ai}(M)
     !
     ! G is a Fock (Coulomb+exchange) transformation, and M is determined from X and Y:
     ! M = Y + Y^T - X - X^T
     !
     ! For the construction of M it is implicitly understood that X and Y have been
     ! transformed to the AO basis.
     ! Once RHS has been determined, kappa is found by solving:
     !
     ! E2[kappa] = RHS
     !
     ! where E2 is the Hessian transformation, see dec_solve_kappa_equation.


     ! Single fragment:
     ! ij in X_{ij} belongs to CentralAtom
     ! ab in X_{ij} belongs to CentralAtom
     !
     ! Pair fragment:
     ! i belongs to CentralAtom and j belongs to CentralAtom2 - or vice versa
     ! a belongs to CentralAtom and b belongs to CentralAtom2 - or vice versa


     !> Central atom for fragment
     integer :: CentralAtom
     !> Second central atom - only used for pair fragments
     integer :: CentralAtom2
     !> Number of basis functions in fragment
     integer :: nbasis
     !> Number of virtual AOS orbitals in fragment
     integer :: nvirt
     !> Number of occupied AOS orbitals in fragment (only valence for frozen core)
     integer :: nocc
     !> Number of occupied core+valence AOS orbitals (only different from nocc for frozen core)
     integer :: nocctot
     !> Fragment energy (for single fragment or pair fragment)
     real(realk) :: energy
     !> Only pair frags: Distance between (super) fragments in pair (zero for single fragments)
     real(realk) :: pairdist

     !> Number of EOS atoms (1 for atomic fragment, 2 for pair fragment)
     integer :: nEOSatoms
     !> List of  EOS atoms
     integer, pointer :: EOSatoms(:) => null()

     !> Indices for atomic basis functions in the list of basis functions for full molecule
     integer,pointer :: basis_idx(:) => null()

     !> Fragment component of virt-virt block of MP2 density matrix (MO basis)
     real(realk), pointer :: Y(:,:) => null()
     !> Fragment component of occ-occ block of MP2 density matrix (MO basis)
     real(realk), pointer :: X(:,:) => null()

     !> X and Y components of the MP2 correlation density matrix transformed to AO basis
     real(realk),pointer :: rho(:,:) => null()

     !> Virt-occ component of Phi matrix (needed to construct RHS for kappa-bar multiplier equation)
     !> Note: Even for frozen core the occupied index refers to both core+valence!
     real(realk), pointer :: Phivo(:,:) => null()
     !> Occ-virt component of Phi matrix (needed to construct RHS for kappa-bar multiplier equation)
     real(realk), pointer :: Phiov(:,:) => null()

  end type mp2dens



  !> Structure for fragment contribution to MP2 gradient
  type mp2grad

     ! Note: Many of the matrices needed for the MP2 gradient are also required for the MP2 density.
     ! Hence, the MP2 density structure is a subset of the MP2 gradient structure.

     !> Fragment components for MP2 correlation density matrix
     type(mp2dens) :: dens

     !> Number of atoms used to describe MOs in fragment (atomic extent)
     integer :: natoms

     !> Atomic indices for atoms in atomic extent
     integer, pointer :: atoms_idx(:) => null()

     !> Occ-occ component of Phi matrix (needed to construct reorthonormalization matrix)
     real(realk), pointer :: Phioo(:,:) => null()
     !> Virt-virt component of Phi matrix (needed to construct reorthonormalization matrix)
     real(realk), pointer :: Phivv(:,:) => null()

     !> Ltheta contribution to gradient -- dimension: (3,natoms)
     real(realk), pointer :: Ltheta(:,:) => null()

     !> Phi matrix in AO matrix (all compontents occ-occ, virt-virt, occ-virt, virt-occ)
     real(realk),pointer :: PhiAO(:,:) => null()

  end type mp2grad

  !> Batch sizes used for MP2 integral/amplitude calculation
  !> (See get_optimal_batch_sizes_for_mp2_integrals for details)
  type mp2_batch_construction
     !> Maximum allowed size of alpha batch
     integer :: MaxAllowedDimAlpha
     !> Maximum allowed size of gamma batch
     integer :: MaxAllowedDimGamma
     !> Maximum allowed size of virtual batch
     integer :: virtbatch
     !> Sizes of the four temporary arrays in step 1 of integral/amplitude scheme (AO integral part)
     integer(kind=long),dimension(4) :: size1
     !> Sizes of the four temporary arrays in step 2 of integral/amplitude scheme (virtual batch part)
     integer(kind=long),dimension(4) :: size2
     !> Sizes of the four temporary arrays in step 3 of integral/amplitude scheme (after integral loop)
     integer(kind=long),dimension(4) :: size3

  end type mp2_batch_construction

  ! Simple structure for pointer, which points to some limited chunk of larger array
  type mypointer
     !> Start index in larger array
     integer(kind=long) :: start
     !> End index in larger array
     integer(kind=long) :: end
     !> Number of elements = end-start+1
     integer(kind=long) :: N
     !> Pointer
     real(realk),pointer :: p(:) => null()
  end type mypointer


  !> Job list of fragment calculations, both single and pair
  !> Ideally they are listed in order of size with the largest jobs first.
  !> Also includes MPI performance statistics for each job.
  type joblist
     ! Number of superfragment jobs
     integer :: njobs

     ! All pointers below has the dimension njobs
     ! ------------------------------------------

     ! Atom 1 in super fragment (dimension: njobs)
     integer,pointer :: atom1(:) 
     ! Atom 2 in super fragment (dimension: njobs)   (NOTE: atom2=0 for single fragments)
     integer,pointer :: atom2(:) 
     ! Size of job (dimension: njobs)
     integer,pointer :: jobsize(:) 
     ! Is a given job done (true) or not (false) (dimension: njobs)
     logical,pointer :: jobsdone(:) 

     ! MPI statistics

     !> Number of nodes in MPI slot (local master + local slaves)
     integer,pointer:: nslaves(:)
     !> Number of occupied orbitals for given fragment (AOS)
     integer,pointer :: nocc(:)
     !> Number of virtual orbitals for given fragment (AOS)
     integer,pointer :: nvirt(:)
     !> Number of basis functions for given fragment
     integer,pointer :: nbasis(:)
     !> Number of MPI tasks used for integral/transformation (nalpha*ngamma)
     integer,pointer :: ntasks(:)
     !> FLOP count for all local nodes (local master + local slaves)
     real(realk),pointer :: flops(:)
     !> Time used for local master
     real(realk),pointer :: LMtime(:)
     !> Measure of load distribution:
     !> { (total times for nodes) / (time for local master) } / number of nodes
     real(realk),pointer :: load(:)
  end type joblist

  !> Bookkeeping when distributing DEC MPI jobs.
   TYPE traceback
      INTEGER :: na,ng,ident
   END TYPE traceback
    

   !> Integral batch handling
   TYPE batchTOorb
     INTEGER,pointer :: orbindex(:)
     INTEGER :: norbindex
  END TYPE batchTOorb

  !> \brief Grid box handling for analyzing orbitals in specific parts of space
  !> for single precision real grid points
  !> \author Kasper Kristensen
  !> \date November 2012
  type SPgridbox
     !> Center of grid box
     real(4) :: center(3)
     !> Distance between neighbouring points in grid box
     real(4) :: delta
     !> Number of grid points in each x,y,z direction measured from center
     !> (is is assumed that all sides of the grid box have the same length)
     integer :: n
     !> Number of grid points in each direction, nd = 2n+1
     !> (Somewhat redundant since it is given by n, but nice to have direct access to)
     integer :: nd
     !> Grid point values for (x,y,z) coordinates, e.g. entry(1,1,2n+1) is the
     !> point with minimum x and y values and maximum z value.
     real(4), pointer :: val(:,:,:)
  end type SPgridbox
  

  !> Information about DEC calculation
  !> We keep it as a global parameter for now.
  type(DECsettings) :: DECinfo

end module dec_typedef_module