!> @file 
!> contains many structure and associated subroutine
MODULE TYPEDEFTYPE
 use precision
 use dft_typetype
 use molecule_typetype
 use basis_typetype
 use io_type
 use integral_type
 use ao_typetype
 use lsmatrix_type
 use LSTENSOR_typetype
 use matrix_module
 use Integralparameters
 use integralOutput_typetype
#ifdef VAR_LSMPI
 use infpar_module
#endif
TYPE INTEGERP
INTEGER,pointer :: p
END TYPE INTEGERP

!*****************************************
!*
!* OBJECT CONTAINING INFORMATION ABOUT THE CALCULATION
!* THE DALTON INPUT FILE
!*
!*****************************************
TYPE integralconfig
!PARAMETERS FROM **INTEGRALS   DECLERATION
LOGICAL  :: CONTANG  !Specifies that the AO-shell ordering is contracted first then
                     ! angular components (for genereally contracted functions)
LOGICAL  :: NOGCINTEGRALTRANSFORM
LOGICAL  :: FORCEGCBASIS
LOGICAL  :: noOMP
LOGICAL  :: UNRES
LOGICAL  :: CFG_LSDALTON !.RUN LINSCA SPECIFIED 
LOGICAL  :: TRILEVEL
LOGICAL  :: DOPASS
LOGICAL  :: DENSFIT
LOGICAL  :: DF_K
LOGICAL  :: INTEREST
LOGICAL  :: LINSCA
LOGICAL  :: MATRICESINMEMORY
LOGICAL  :: MEMDIST
LOGICAL  :: LOW_ACCURACY_START
!*DENSFIT PARAMETERS

!*LINSCA PRINT PARAMETERS
INTEGER  :: LINSCAPRINT
INTEGER  :: AOPRINT
INTEGER  :: MOLPRINT
INTEGER  :: INTPRINT
INTEGER  :: BASPRINT
LOGICAL  :: PRINTATOMCOORD
!*MAIN INTEGRAL PARAMETERS
LOGICAL  :: NOBQBQ ! switches off the point charge--point charge repulsion contribution (NUCPOT)
LOGICAL  :: JENGINE
LOGICAL  :: LOCALLINK
REAL(REALK)  :: LOCALLINKmulthr
LOGICAL  :: LOCALLINKDcont
REAL(REALK)  :: LOCALLINKDthr
LOGICAL  :: LOCALLINKsimmul
INTEGER  :: LOCALLINKoption
LOGICAL  :: LOCALLINKincrem
INTEGER  :: FTUVmaxprim
INTEGER  :: maxpasses
LOGICAL  :: FMM
LOGICAL  :: LINK
!Line search density accelerated screening
LOGICAL  :: LSDASCREEN
LOGICAL  :: LSDAJENGINE
LOGICAL  :: LSDACOULOMB
LOGICAL  :: LSDALINK
INTEGER  :: LSDASCREEN_THRLOG
!Density accelerated screenig
LOGICAL  :: DAJENGINE
LOGICAL  :: DACOULOMB
LOGICAL  :: DALINK
INTEGER  :: DASCREEN_THRLOG
LOGICAL  :: DEBUGOVERLAP
LOGICAL  :: DEBUG4CENTER
LOGICAL  :: DEBUG4CENTER_ERI
LOGICAL  :: DEBUGPROP
LOGICAL  :: DEBUGGEN1INT
LOGICAL  :: DEBUGCGTODIFF
LOGICAL  :: DEBUGEP
LOGICAL  :: DEBUGscreen
LOGICAL  :: DEBUGGEODERIVOVERLAP
LOGICAL  :: DEBUGGEODERIVKINETIC
LOGICAL  :: DEBUGGEODERIVEXCHANGE
LOGICAL  :: DEBUGGEODERIVCOULOMB
LOGICAL  :: DEBUGMAGDERIV
LOGICAL  :: DEBUGMAGDERIVOVERLAP
LOGICAL  :: DEBUGCCFRAGMENT
LOGICAL  :: DEBUGKINETIC
LOGICAL  :: DEBUGNUCPOT
LOGICAL  :: DEBUGGGEM
LOGICAL  :: DEBUGLSlib
LOGICAL  :: DEBUGUncontAObatch
LOGICAL  :: DEBUGDECPACKED
LOGICAL  :: DO4CENTERERI
LOGICAL  :: OVERLAP_DF_J
LOGICAL  :: PARI_J
LOGICAL  :: PARI_K
LOGICAL  :: SIMPLE_PARI
LOGICAL  :: NON_ROBUST_PARI
LOGICAL  :: PARI_CHARGE
LOGICAL  :: PARI_DIPOLE
LOGICAL  :: TIMINGS
LOGICAL  :: nonSphericalETUV
LOGICAL  :: HIGH_RJ000_ACCURACY
!*FMM PARAMETERS
Integer     :: MM_LMAX
Integer     :: MM_TLMAX
REAL(realk) :: MM_SCREEN
LOGICAL     :: NO_MMFILES
LOGICAL     :: MM_NO_ONE
LOGICAL     :: CREATED_MMFILES
LOGICAL     :: USEBUFMM
LOGICAL     :: DO_MMGRD
LOGICAL     :: MM_NOSCREEN
Integer     :: MMunique_ID1
!*BASIS PARAMETERS
LOGICAL  :: ATOMBASIS
LOGICAL  :: BASIS
LOGICAL  :: AUXBASIS
LOGICAL  :: CABSBASIS
LOGICAL  :: JKBASIS
LOGICAL  :: NOFAMILY
LOGICAL  :: Hermiteecoeff
LOGICAL  :: DoSpherical
LOGICAL  :: UNCONT !FORCE UNCONTRACTED BASIS
LOGICAL  :: NOSEGMENT !DISABLE SEGMENTS 

!* JOB REQUESTS
LOGICAL  :: DO3CENTEROVL
LOGICAL  :: DO2CENTERERI
INTEGER  :: CARMOM
INTEGER  :: SPHMOM
LOGICAL  :: MIXEDOVERLAP

!*CAUCHY-SCHWARZ INTEGRAL PARAMETERS
!THE ONE THRESHOLD TO RULE THEM ALL
REAL(REALK):: THRESHOLD  
!THESE THRESHOLDS TELL HOW THEY SHOULD BE SET COMPARED TO THE ONE THRESHOLD
REAL(REALK) :: CS_THRESHOLD
REAL(REALK) :: OE_THRESHOLD
REAL(REALK) :: PS_THRESHOLD
Real(realk) :: OD_THRESHOLD
Real(realk) :: PARI_THRESHOLD
REAL(REALK) :: J_THR
REAL(REALK) :: K_THR
REAL(REALK) :: ONEEL_THR
!OTHER CAUCHY-SCHWARZ INTEGRAL PARAMETERS
LOGICAL  :: CS_SCREEN
LOGICAL  :: PARI_SCREEN
LOGICAL  :: OE_SCREEN
LOGICAL  :: saveGABtoMem
!*PRIMITIVE INTEGRAL PARAMETERS
LOGICAL  :: PS_SCREEN
LOGICAL  :: PS_DEBUG
!Screen OD-batches by AO-batch extent
LOGICAL  :: OD_SCREEN
!Multipole Based Integral Estimate screening 
LOGICAL  :: MBIE_SCREEN
!Fragment molecule into to distinct parts, and construct matrices block by block
LOGICAL     :: FRAGMENT
!Approximate number of atoms per fragment
Integer     :: numAtomsPerFragment

!FMM
INTEGER     :: LU_LUINTM
INTEGER     :: LU_LUINTR
INTEGER     :: LU_LUINDM
INTEGER     :: LU_LUINDR
LOGICAL     :: LR_EXCHANGE_DF
LOGICAL     :: LR_EXCHANGE_PARI
LOGICAL     :: LR_EXCHANGE
LOGICAL     :: ADMM_EXCHANGE
LOGICAL     :: ADMM_GCBASIS
LOGICAL     :: ADMM_DFBASIS
LOGICAL     :: ADMM_JKBASIS
LOGICAL     :: ADMM_MCWEENY
LOGICAL     :: SR_EXCHANGE
!Coulomb attenuated method CAM parameters
LOGICAL     :: CAM
REAL(REALK) :: CAMalpha
REAL(REALK) :: CAMbeta
REAL(REALK) :: CAMmu
!DFT PARAMETERS
TYPE(DFTparam) :: DFT
!EXCHANGE FACTOR
REAL(REALK) :: exchangeFactor
!MOLECULE INFO
INTEGER     :: nelectrons
INTEGER     :: molcharge

! TESTING FUNCTIONALITIES FOR DEC
LOGICAL     :: run_dec_gradient_test
END TYPE integralconfig

TYPE LSINTSCHEME
!PARAMETERS FROM **INTEGRALS   DECLERATION
LOGICAL  :: NOBQBQ ! switches off the point charge--point charge repulsion contribution (NUCPOT)
LOGICAL  :: noOMP
LOGICAL  :: CFG_LSDALTON
LOGICAL  :: DOPASS
LOGICAL  :: DENSFIT
LOGICAL  :: DF_K
LOGICAL  :: INTEREST
LOGICAL  :: MATRICESINMEMORY
LOGICAL  :: MEMDIST
INTEGER  :: AOPRINT
INTEGER  :: INTPRINT
LOGICAL  :: JENGINE
INTEGER  :: FTUVmaxprim
INTEGER  :: maxpasses
LOGICAL  :: FMM
LOGICAL  :: LINK
!Line search density accelerated screening
LOGICAL  :: LSDASCREEN
LOGICAL  :: LSDAJENGINE
LOGICAL  :: LSDACOULOMB
LOGICAL  :: LSDALINK
INTEGER  :: LSDASCREEN_THRLOG
!Density accelerated screenig
LOGICAL  :: DAJENGINE
LOGICAL  :: DACOULOMB
LOGICAL  :: DALINK
INTEGER  :: DASCREEN_THRLOG
!debug options
LOGICAL  :: DEBUGOVERLAP
LOGICAL  :: DEBUG4CENTER
LOGICAL  :: DEBUG4CENTER_ERI
LOGICAL  :: DEBUGCCFRAGMENT
LOGICAL  :: DEBUGKINETIC
LOGICAL  :: DEBUGNUCPOT
LOGICAL  :: DO4CENTERERI
LOGICAL  :: OVERLAP_DF_J
LOGICAL  :: PARI_J
LOGICAL  :: PARI_K
LOGICAL  :: SIMPLE_PARI
LOGICAL  :: NON_ROBUST_PARI
LOGICAL  :: PARI_CHARGE
LOGICAL  :: PARI_DIPOLE
LOGICAL  :: TIMINGS
LOGICAL  :: nonSphericalETUV
LOGICAL  :: HIGH_RJ000_ACCURACY
!*FMM PARAMETERS
Integer     :: MM_LMAX
Integer     :: MM_TLMAX
REAL(realk) :: MM_SCREEN
LOGICAL     :: NO_MMFILES
LOGICAL     :: MM_NO_ONE
LOGICAL     :: CREATED_MMFILES
LOGICAL     :: USEBUFMM
LOGICAL     :: DO_MMGRD
LOGICAL     :: MM_NOSCREEN
Integer     :: MMunique_ID1
INTEGER     :: LU_LUINTM
INTEGER     :: LU_LUINTR
INTEGER     :: LU_LUINDM
INTEGER     :: LU_LUINDR
!*BASIS PARAMETERS
LOGICAL  :: AUXBASIS
LOGICAL  :: CABSBASIS
LOGICAL  :: JKBASIS
LOGICAL  :: NOFAMILY
LOGICAL  :: Hermiteecoeff
LOGICAL  :: DoSpherical
LOGICAL  :: UNCONT !FORCE UNCONTRACTED BASIS
LOGICAL  :: NOSEGMENT !DISABLE SEGMENTS 
LOGICAL  :: ContAng  !Specifies that the AO-shell ordering is contracted first then
                     !angular components (for genereally contracted functions) 
                     !Default is angular first then contracted

!* JOB REQUESTS
LOGICAL     :: DO3CENTEROVL
LOGICAL     :: DO2CENTERERI
INTEGER     :: CARMOM
INTEGER     :: SPHMOM
INTEGER     :: CMORDER
INTEGER     :: CMimat
LOGICAL     :: MIXEDOVERLAP
!If OD_MOM true expand multipole moments around OD-center, else use MOM_CENTER
LOGICAL     :: OD_MOM 
Real(realk) :: MOM_CENTER(3)

!*CAUCHY-SCHWARZ INTEGRAL PARAMETERS
!THE ONE THRESHOLD TO RULE THEM ALL
REAL(REALK):: THRESHOLD  
!THESE THRESHOLDS TELL HOW THEY SHOULD BE SET COMPARED TO THE ONE THRESHOLD
REAL(REALK) :: CS_THRESHOLD
REAL(REALK) :: OE_THRESHOLD
REAL(REALK) :: PS_THRESHOLD
Real(realk) :: OD_THRESHOLD
REAL(REALK) :: PARI_THRESHOLD
REAL(REALK) :: J_THR
REAL(REALK) :: K_THR
REAL(REALK) :: ONEEL_THR
REAL(REALK) :: IntThreshold
!OTHER CAUCHY-SCHWARZ INTEGRAL PARAMETERS
LOGICAL  :: CS_SCREEN
LOGICAL  :: PARI_SCREEN
LOGICAL  :: OE_SCREEN
LOGICAL  :: savegabtomem
LOGICAL  :: ReCalcGab
LOGICAL  :: CS_int
LOGICAL  :: PS_int
!*PRIMITIVE INTEGRAL PARAMETERS
LOGICAL  :: PS_SCREEN
LOGICAL  :: PS_DEBUG
!Screen OD-batches by AO-batch extent
LOGICAL     :: OD_SCREEN 
!Multipole Based Integral Estimate screening 
LOGICAL     :: MBIE_SCREEN
!Fragment molecule into to distinct parts, and construct matrices block by block
LOGICAL     :: FRAGMENT
!Approximate number of atoms per fragment
Integer     :: numAtomsPerFragment

LOGICAL     :: LR_EXCHANGE_DF
LOGICAL     :: LR_EXCHANGE_PARI
LOGICAL     :: LR_EXCHANGE
LOGICAL     :: SR_EXCHANGE

LOGICAL     :: ADMM_EXCHANGE
LOGICAL     :: ADMM_GCBASIS
LOGICAL     :: ADMM_DFBASIS
LOGICAL     :: ADMM_JKBASIS
LOGICAL     :: ADMM_MCWEENY
!Coulomb attenuated method CAM parameters
LOGICAL     :: CAM
REAL(REALK) :: CAMalpha
REAL(REALK) :: CAMbeta
REAL(REALK) :: CAMmu
REAL(REALK) :: exchangeFactor !EXCHANGE FACTOR
!DFT PARAMETERS
TYPE(DFTparam) :: DFT

LOGICAL :: INCREMENTAL !Use incremental scheme (density-difference KS-matrix build)
  
logical   :: DO_PROP
integer   :: PropOper
END TYPE LSINTSCHEME

!*****************************************
!*
!* OBJECT CONTAINING BASISSETLIBRARY
!*
!*****************************************
TYPE BASISSETLIBRARYITEM
Character(len=80)         :: BASISSETNAME(maxBasisSetInLIB)
!'pointcharge' if no basissets  
integer                   :: nbasissets   
integer                   :: nCharges(maxBasisSetInLIB)
real(realk)               :: Charges(maxBasisSetInLIB,maxNumberOfChargesinLIB)
logical                   :: pointcharges(maxBasisSetInLIB,maxNumberOfChargesinLIB)
logical                   :: phantom(maxBasisSetInLIB,maxNumberOfChargesinLIB)
logical                   :: DunningsBasis
END TYPE BASISSETLIBRARYITEM

TYPE BLOCK
Integer :: fragment1
Integer :: fragment2
Logical :: sameFragments
Integer :: nbast1
Integer :: nbast2
Integer :: nprimbast1
Integer :: nprimbast2
integer :: startOrb1
integer :: startOrb2
integer :: startprimOrb1
integer :: startprimOrb2
Integer :: node
Integer :: nAtoms1
Integer :: nAtoms2
END TYPE BLOCK

!******** BLOCKINFO ********
TYPE BLOCKINFO
Integer :: numBlocks
Logical :: sameAOs
TYPE(BLOCK),pointer :: blocks(:)
END TYPE BLOCKINFO


!******** FRAGMENTINFO ********
TYPE FRAGMENTINFO
Integer :: numFragments
Logical :: numberOrbialsSet
Integer :: atomsInMolecule
Integer,pointer :: fragmentIndex(:)  !Index giving the fragment of each atom
Integer,pointer :: nAtoms(:) !atoms in each fragment
Integer,pointer :: AtomicIndex(:,:) !list of atoms in each fragment
! First dimension numFragments, second dimension for different basis sets:
!    1: Regular, 2: DF-Aux, 3: CABS 4: JK 5: VALENCE
Integer,pointer :: nContOrb(:,:)
Integer,pointer :: nPrimOrb(:,:)
Integer,pointer :: nStartContOrb(:,:)
Integer,pointer :: nStartPrimOrb(:,:)
END TYPE FRAGMENTINFO

TYPE FRAGMENTINFO_PT
TYPE(FRAGMENTINFO),pointer :: p
END TYPE FRAGMENTINFO_PT

!One for each of the four AO's
TYPE FRAGMENTITEM
!TYPE(MOLECULE_PT) :: MOLECULE(4)
INTEGER               :: numFragments(4) !Number of fragments to partition each molecule into
TYPE(FRAGMENTINFO_PT) :: INFO(4)
Logical               :: infoAllocated(4) != .FALSE. not allowed in fortran 90
Logical               :: identical(4,4)
TYPE(BLOCKINFO)       :: LHSblock
integer               :: iLHSBlock
TYPE(BLOCKINFO)       :: RHSblock
integer               :: iRHSBlock
END TYPE FRAGMENTITEM

TYPE FRAGMENT_PT
TYPE(FRAGMENTITEM),pointer :: p
END TYPE FRAGMENT_PT

!*****************************************
!*
!* OBJECT CONTAINING INFORMATION ABOUT 
!* THE INPUT TO THE DALTON PROGRAM
!*
!*****************************************
TYPE DALTONINPUT
LOGICAL                    :: DO_DFT
REAL(REALK)                :: POTNUC
integer                    :: nfock ! number of fock matrix build
TYPE(MOLECULEINFO),pointer :: MOLECULE
TYPE(integralconfig)       :: DALTON
TYPE(BASISINFO),pointer    :: BASIS
TYPE(IOITEM)               :: IO
INTEGER                    :: numFragments !Number of fragments to partition molecule into
Integer                    :: numNodes     !Number of MPI nodes
Integer                    :: node         !Integer value defining the node number
!if you add a structure to this type remember to add it to MPI_ALLOC_DALTONINPUT
END TYPE DALTONINPUT

#ifdef VAR_LSMPI
TYPE AOBATCHINFO
integer         :: nBatches
integer,pointer :: nPrim(:)
integer,pointer :: maxAng(:)
integer         :: GlobalStartBatchindex
END TYPE AOBATCHINFO

TYPE AOATOMINFO
integer                   :: nAtoms
integer                   :: nTotBatch
type(AOBATCHINFO),pointer :: batch(:) !Length nAtoms
END TYPE AOATOMINFO
#endif

TYPE REDUCEDSCREENINGINFO
LOGICAL                   :: isset
#ifdef VAR_LSMPI
TYPE(AOATOMINFO)         :: AO(4)
integer(kind=short),pointer  :: LHSGAB(:,:) !nbatches*nbatches
integer(kind=short),pointer  :: RHSGAB(:,:) 
integer(kind=short),pointer  :: LHSDMAT(:,:)
integer(kind=short),pointer  :: RHSDMAT(:,:)
integer(kind=short)      :: maxgabRHS
integer(kind=short)      :: maxgabLHS
integer(kind=short)      :: maxDmatRHS
integer(kind=short)      :: maxDmatLHS
integer                  :: nbatches(4)
LOGICAL                  :: LHSDMATset
LOGICAL                  :: RHSDMATset
INTEGER(short)           :: CS_THRLOG
#endif
END TYPE REDUCEDSCREENINGINFO

!*****************************************
!*
!* OBJECT CONTAINING INFORMATION ABOUT 
!* THE INTEGRAL SETTINGS
!*  - used for interfacing with LSint (IntegralInterface.f90)
!*
!*****************************************
!> \brief Contrains the settings for the ls-integral routines
TYPE LSSETTING
! ************************************************************************************************************
! *  
! *                      READ THIS BEFORE ADDING A NEW VARIABLE TO LSSETTING
! *  
! *        A LSSETTINGXXX comment should be added to the end of the line for each new
! *        variable, where XXX should be a unique number. This is to make the mpicopy_setting
! *        copy_setting and similar routines easier to debug!
! *  
! *        ToDo Find a better solution
! *  
! ************************************************************************************************************
INTEGER(kind=ls_mpik)      :: comm !MPI communicator
LOGICAL                    :: IntegralTransformGC                                                  
LOGICAL                    :: DO_DFT                                                               
REAL(REALK)                :: EDISP  !empiricial dispersion correction                             
INTEGER                    :: nAO != 4 Number of AOs, e.g. the 4 for four-center                   
                                     !two-electron Coulomb-repulsion integrals (ab|cd)                                                     
TYPE(MOLECULE_PT),pointer  :: MOLECULE(:) !One for each AO                                         
TYPE(BASIS_PT),pointer     :: BASIS(:)    !One for each AO                                         
TYPE(MOLECULE_PT),pointer  :: FRAGMENT(:) !One for each AO                                         
TYPE(LSINTSCHEME)          :: SCHEME !The specifications on how to run the integrals               
TYPE(IOITEM)               :: IO !Keeps track of the different files that are stored on disk       
!TYPE(SCREENITEM)           :: SCREEN !Keeps track of the different screening matrices             
INTEGER,pointer            :: Batchindex(:) !One for each AO, zero if full AObatch is requested    
INTEGER,pointer            :: Batchsize(:) !One for each AO                                        
INTEGER,pointer            :: Batchdim(:) !dim for teach AO Batchindex, zero if full AObatch is requested
INTEGER,pointer            :: molID(:) !unique identifier for different molecules, used for screening matrices, default 0 
LOGICAL,pointer            :: sameMOL(:,:)  !Specifies if the different MOLECULES are identical
LOGICAL,pointer            :: sameBAS(:,:)  !Specifies if the different BASIS are identical    
LOGICAL,pointer            :: sameFRAG(:,:) !Specifies if the different FRAGMENTS are identical
LOGICAL,pointer            :: molBuild(:) !Specifies if the MOLECULEs have been built          
                                          !(i.e. not set to point to a molecule)               
LOGICAL,pointer            :: basBuild(:) !Specifies if the BASISes have been built            
LOGICAL,pointer            :: fragBuild(:) !Specifies if the FRAGMENTs have been built         
!===========================================================================                                                              
!Density-matrix information:                                                                                                 
! The main integral drivers (Thermite) uses LSTENSOR-type matrices/tensors for storage of                                     
! density-matrices, integrals, Fock-matrices and so on. On calling the II-routines however,                                  
! there are two options, either calling them with MATRIX-type or with REAL(REALK)-type matrices.
TYPE(LSTENSOR),pointer     :: lst_dLHS   !LHS density in LSTENSOR format (used in integral routines)
TYPE(LSTENSOR),pointer     :: lst_dRHS   !RHS density in LSTENSOR format                            
TYPE(matrixp),pointer      :: DmatLHS(:) !Used for passing LHS density                              
TYPE(matrixp),pointer      :: DmatRHS(:) !Used for passing RHS density                              
Real(realk),pointer        :: DfullLHS(:,:,:) !Used for passing LHS density                         
Real(realk),pointer        :: DfullRHS(:,:,:) !Used for passing RHS density                         
Integer                    :: nDmatLHS   !Number of LHS densities                                   
Integer                    :: nDmatRHS   !Number of RHS densities                                   
Logical                    :: lstensor_attached !Specified if lstensor has been attached or not     
Logical                    :: LHSdmat    !Specifying whether the LHS density-matrix has been assigned
Logical                    :: RHSdmat    !Specifying whether the RHS density-mat                     
Logical                    :: LHSdmatAlloc   !Specifying if LHSdmatAlloc alloced                     
Logical                    :: RHSdmatAlloc   !Specifying if RHSdmatAlloc alloced                     
Logical                    :: LHSdfull    !Specifying whether the LHS density-matrix has been assigned
Logical                    :: RHSdfull    !Specifying whether the RHS density-matrix has been assigned
Logical                    :: LHSdalloc   !Specifying if LHSdfull alloced                             
Logical                    :: RHSdalloc   !Specifying if RHSdfull alloced      
Logical                    :: LHSSameAsRHSDmat !if the input%lst_DLHS should point to the RHS dmat
!  Screening matrices 
type(lstensor),pointer    :: LST_GAB_LHS                                                              
type(lstensor),pointer    :: LST_GAB_RHS                                                              
integer                    :: iLST_GAB_LHS !index in screenitem                                       
integer                    :: iLST_GAB_RHS                                                            
integer(kind=short)        :: CS_MAXELM_LHS                                                           
integer(kind=short)        :: CS_MAXELM_RHS                                                           
integer(kind=short)        :: PS_MAXELM_LHS                                                           
integer(kind=short)        :: PS_MAXELM_RHS                                                           
!===========================================================================
!> \param Specifying the symmetry of the LHS density-matrix for each nDmatLHS (0 not set, 1=sym, 2=anti-sym, 3=no-sym, 4=zero)
Integer,pointer            :: DsymLHS(:)                                                   
!> \param Specifying the symmetry of the RHS density-matrix for each nDmatRHS (0 not set, 1=sym, 2=anti-sym, 3=no-sym, 4=zero)
Integer,pointer            :: DsymRHS(:)                                                   
Integer                    :: LHSdmatAOindex1                                              
Integer                    :: LHSdmatAOindex2                                              
Integer                    :: RHSdmatAOindex1                                              
Integer                    :: RHSdmatAOindex2                                              
! Fragment and node info
INTEGER                    :: numFragments !Number of fragments to partition molecule into 
TYPE(FRAGMENTITEM)         :: FRAGMENTS    !Information about the fragments                
Integer(kind=ls_mpik)      :: numNodes     !Number of MPI nodes                            
!Integer value defining the node number within the lssetting%comm communicator
Integer(kind=ls_mpik)      :: node         
!TYPE(OUTPUTSPEC)           :: OUTSPEC !The specifications on how the output should be given
TYPE(INTEGRALOUTPUT)       :: OUTPUT  !The structure containing the output                  
!if you add a structure to this type remember to add it to MPI_ALLOC_DALTONINPUT
TYPE(GaussianGeminal)      :: GGem !Information about the Gaussian geminal expansion        
TYPE(ReducedScreeningInfo) :: RedCS !Batchinformation and batchwise screening and density matrices  
END TYPE LSSETTING

!*****************************************
!*
!* OBJECT CONTAINING INFORMATION ABOUT 
!* THE INTEGRAL SETTINGS OBJECT
!*   - used for IntegralInterface.f90
!*
!*****************************************
TYPE LSITEM
TYPE(DALTONINPUT) :: INPUT   !Input handling (of DALTON.INP and MOLECULE.INP)
TYPE(LSSETTING)   :: SETTING !Settings for integral evaluation
INTEGER           :: LUPRI = -1  !Output-file unit number
INTEGER           :: LUERR = -1  !Error-file unit number
INTEGER           :: optlevel !1=atoms, 2=valence, 3=full
LOGICAL           :: fopen = .false. !Determines wether the LSDALTON.OUT and LSDALTON.ERR has been opened
END TYPE LSITEM

!*****************************************
!*
!* OBJECT CONTAINING INFORMATION ABOUT 
!* THE GEOMETRICAL HESSIAN SETTINGS
!*
!*****************************************
TYPE geoHessianConfig
   !PARAMETERS FROM **GEOHESSIAN DECLARATION
   LOGICAL  :: do_geoHessian
   LOGICAL  :: testContrib
   LOGICAL  :: DebugGen1Int
   INTEGER  :: IntPrint
END TYPE geoHessianConfig


contains

!Added to avoid "has no symbols" linking warning
subroutine TYPEDEFTYPE_void()
end subroutine TYPEDEFTYPE_void

end MODULE TYPEDEFTYPE
