!> @file 
!> contains many structure and associated subroutine
MODULE TYPEDEF
 use TYPEDEFTYPE
 use files
 use precision
 use dft_type
 use molecule_type
 use basis_type
 use dft_typetype
 use molecule_typetype
 use basis_typetype
 use io
 use io_type
 use integral_type
 use ao_type
 use lsmatrix_type
 use matrix_module
 use matrix_util
 use integralOutput_type
 use integralOutput_typetype
 use LSTENSOR_OPERATIONSMOD
 use LSTENSOR_typetype
 use Integralparameters
#ifdef VAR_LSMPI
 use infpar_module
#endif
INTERFACE retrieve_output
   MODULE PROCEDURE retrieve_output_mat_single, &
        & retrieve_output_mat_array,&
        & retrieve_output_5dim, retrieve_output_4dim,&
        & retrieve_output_2dim, retrieve_output_1dim,&
        & retrieve_output_3dim, retrieve_output_lstensor,&
        & retrieve_output_maxGabelm
END INTERFACE

INTERFACE typedef_setMolecules
  MODULE PROCEDURE typedef_setMolecules_4
  MODULE PROCEDURE typedef_setMolecules_2
  MODULE PROCEDURE typedef_setMolecules_1
  MODULE PROCEDURE typedef_setMolecules_2_1
  MODULE PROCEDURE typedef_setMolecules_1_1
  MODULE PROCEDURE typedef_setMolecules_1_1_1
  MODULE PROCEDURE typedef_setMolecules_1_1_1_1
END INTERFACE !typedef_setMolecules

Contains
subroutine set_integral_comm(setting,comm)
implicit none
TYPE(LSSETTING)   :: SETTING
integer :: comm
setting%comm = comm
end subroutine set_integral_comm

!> \brief write lsitem to disk
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param LS lsitem to be written
SUBROUTINE write_lsitem_to_disk(LS)
implicit none
TYPE(LSITEM)    :: LS
!
LOGICAL         :: fileexist  
INTEGER         :: lun,i
call lsquit('write_lsitem_to_disk option disabeled',-1)
!Open lsitem file
!!$INQUIRE(file='lsitem',EXIST=fileexist)
!!$IF(fileexist)THEN
!!$   lun = -1
!!$   CALL LSOPEN(LUN,'lsitem','old','UNFORMATTED')
!!$   call LSclose(LUN,'DELETE')
!!$ENDIF
!!$lun = -1
!!$CALL LSOPEN(lun,'lsitem','new','UNFORMATTED')
!!$
!!$!Write
!!$CALL WRITE_DALTONINPUT_TO_DISK(lun,LS%INPUT)
!!$write(lun) ls%setting%integraltransformGC
!!$
!!$!Close
!!$call LSclose(LUN,'KEEP')

END SUBROUTINE write_lsitem_to_disk

!> \brief read lsitem from disk
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param LS lsitem to be written
SUBROUTINE read_lsitem_from_disk(LS)
implicit none
TYPE(LSITEM)    :: LS
!
LOGICAL         :: fileexist,integraltransformGC
INTEGER         :: lun,i,nbast
call lsquit('read_lsitem_from_disk option disabeled',-1)

!!$INQUIRE(file='lsitem',EXIST=fileexist)
!!$IF(fileexist)THEN
!!$   LS%lupri=-1
!!$   LS%luerr=-1
!!$   lun = -1
!!$   CALL LSOPEN(lun,'lsitem','old','UNFORMATTED')
!!$   REWIND(lun)
!!$   CALL READ_DALTONINPUT_FROM_DISK(lun,LS%INPUT)
!!$   read(lun)integraltransformGC
!!$   call LSclose(LUN,'KEEP')
!!$   CALL typedef_init_setting(ls%setting)
!!$   CALL typedef_set_default_setting(ls%setting,ls%input)
!!$   ls%setting%integraltransformGC = integraltransformGC
!!$   IF(.NOT.ls%input%basis%REGULAR%Gcont.AND.ls%input%BASIS%GCtransAlloc)THEN
!!$      nbast = getNbasis(AORdefault,Contractedinttype,ls%input%MOLECULE,6)
!!$      call write_GCtransformationmatrix(nbast,ls%setting,6)
!!$   ENDIF
!!$ELSE
!!$   CALL LSQUIT('In call to read_lsitem_from_disk FILE: lsitem do not exit ',-1)
!!$ENDIF

END SUBROUTINE read_lsitem_from_disk

!> \brief 
!> \author
!> \date
!> \param 
INTEGER FUNCTION getNbasis(AOtype,intType,MOLECULE,LUPRI)
implicit none
integer           :: AOtype,intType
Integer           :: LUPRI
!Type(DaltonInput) :: DALTON
TYPE(MOLECULEINFO):: MOLECULE
!
integer :: np,nc
IF (AOtype.EQ.AOEmpty) THEN
  nc = 1
  np = 1
ELSEIF (AOtype.EQ.AORegular) THEN
  nc = MOLECULE%nbastREG
  np = MOLECULE%nprimbastREG
ELSEIF (AOtype.EQ.AOdfAux) THEN
  nc = MOLECULE%nbastAUX
  np = MOLECULE%nprimbastAUX
ELSEIF (AOtype.EQ.AOdfCABS) THEN
  nc = MOLECULE%nbastCABS
  np = MOLECULE%nprimbastCABS
ELSEIF (AOtype.EQ.AOdfJK) THEN
  nc = MOLECULE%nbastJK
  np = MOLECULE%nprimbastJK
ELSEIF (AOtype.EQ.AOVAL) THEN
  nc = MOLECULE%nbastVAL
  np = MOLECULE%nprimbastVAL
ELSEIF (AOtype.EQ.AONuclear) THEN
  nc = MOLECULE%nAtoms
  np = MOLECULE%nAtoms
ELSEIF (AOtype.EQ.AOpCharge) THEN
  nc = MOLECULE%nAtoms
  np = MOLECULE%nAtoms
ELSEIF (AOtype.EQ.AOS1p1cSeg)THEN
  nc = 1
  np = 1
ELSEIF (AOtype.EQ.AOS2p1cSeg)THEN
  nc = 1
  np = 2
ELSEIF (AOtype.EQ.AOS2p2cSeg)THEN
  nc = 2
  np = 2
ELSEIF (AOtype.EQ.AOS2p2cGen)THEN
  nc = 2
  np = 2
ELSEIF (AOtype.EQ.AOP1p1cSeg)THEN
  nc = 3
  np = 3
ELSEIF (AOtype.EQ.AOD1p1cSeg)THEN
  nc = 5
  np = 5
ELSE
  WRITE(LUPRI,'(1X,A,I3)') 'Error in getNbasis. Not valid AOtype =', AOtype
  CALL LSQUIT('AOtype not valid in getNbasis',lupri)
ENDIF
IF (intType.EQ.Contractedinttype) THEN
  getNbasis = nc
ELSEIF (intType.EQ.Primitiveinttype) THEN
  getNbasis = np
ELSE
  WRITE(LUPRI,'(1X,A,I3)') 'Error in getNbasis. Not valid intType =',intType
  CALL LSQUIT('Error: intType not valid in getNbasis',lupri)
ENDIF
END FUNCTION getNbasis

#if 0
!> \brief write daltonitem to disk
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lun logical unit number to write to
!> \param dalton the daltonitem structure
SUBROUTINE write_daltonitem_to_disk(lun,DALTON)
implicit none
TYPE(integralconfig),intent(in)   :: DALTON
INTEGER,intent(in)            :: lun

WRITE(LUN) DALTON%CONTANG
WRITE(LUN) DALTON%NOGCINTEGRALTRANSFORM
WRITE(LUN) DALTON%FORCEGCBASIS
WRITE(LUN) DALTON%NOBQBQ
WRITE(LUN) DALTON%NOOMP
WRITE(LUN) DALTON%UNRES
WRITE(LUN) DALTON%CFG_LSDALTON
WRITE(LUN) DALTON%TRILEVEL
WRITE(LUN) DALTON%DOPASS
WRITE(LUN) DALTON%DENSFIT
WRITE(LUN) DALTON%DF_K
WRITE(LUN) DALTON%INTEREST
WRITE(LUN) DALTON%MATRICESINMEMORY
WRITE(LUN) DALTON%MEMDIST
WRITE(LUN) DALTON%LOW_ACCURACY_START
WRITE(LUN) DALTON%LINSCA
WRITE(LUN) DALTON%PRINTATOMCOORD
WRITE(LUN) DALTON%JENGINE
WRITE(LUN) DALTON%LOCALLINK
WRITE(LUN) DALTON%LOCALLINKmulthr
WRITE(LUN) DALTON%LOCALLINKsimmul
WRITE(LUN) DALTON%LOCALLINKoption
WRITE(LUN) DALTON%LOCALLINKincrem
WRITE(LUN) DALTON%LOCALLINKDcont
WRITE(LUN) DALTON%LOCALLINKDthr
WRITE(LUN) DALTON%FMM
WRITE(LUN) DALTON%LINK
WRITE(LUN) DALTON%LSDASCREEN
WRITE(LUN) DALTON%LSDAJENGINE
WRITE(LUN) DALTON%LSDACOULOMB
WRITE(LUN) DALTON%LSDALINK
WRITE(LUN) DALTON%LSDASCREEN_THRLOG
WRITE(LUN) DALTON%DAJENGINE
WRITE(LUN) DALTON%DACOULOMB
WRITE(LUN) DALTON%DALINK
WRITE(LUN) DALTON%DASCREEN_THRLOG
WRITE(LUN) DALTON%DEBUGOVERLAP
WRITE(LUN) DALTON%DEBUG4CENTER
WRITE(LUN) DALTON%DEBUGPROP
WRITE(LUN) DALTON%DEBUGGEN1INT
WRITE(LUN) DALTON%DEBUGCGTODIFF
WRITE(LUN) DALTON%DEBUGEP
WRITE(LUN) DALTON%DEBUGscreen
WRITE(LUN) DALTON%DEBUGGEODERIVOVERLAP
WRITE(LUN) DALTON%DEBUGGEODERIVKINETIC
WRITE(LUN) DALTON%DEBUGGEODERIVEXCHANGE
WRITE(LUN) DALTON%DEBUGGEODERIVCOULOMB
WRITE(LUN) DALTON%DEBUGMAGDERIV
WRITE(LUN) DALTON%DEBUGMAGDERIVOVERLAP
WRITE(LUN) DALTON%DEBUG4CENTER_ERI
WRITE(LUN) DALTON%DEBUGCCFRAGMENT
WRITE(LUN) DALTON%DEBUGKINETIC
WRITE(LUN) DALTON%DEBUGNUCPOT
WRITE(LUN) DALTON%DO4CENTERERI
WRITE(LUN) DALTON%OVERLAP_DF_J
WRITE(LUN) DALTON%DEBUGGGEM
WRITE(LUN) DALTON%DEBUGLSlib
WRITE(LUN) DALTON%DEBUGUncontAObatch
WRITE(LUN) DALTON%DEBUGDECPACKED
WRITE(LUN) DALTON%PARI_J
WRITE(LUN) DALTON%PARI_K
WRITE(LUN) DALTON%SIMPLE_PARI
WRITE(LUN) DALTON%NON_ROBUST_PARI
WRITE(LUN) DALTON%PARI_CHARGE
WRITE(LUN) DALTON%PARI_DIPOLE
WRITE(LUN) DALTON%TIMINGS
WRITE(LUN) DALTON%nonSphericalETUV
WRITE(LUN) DALTON%HIGH_RJ000_ACCURACY
WRITE(LUN) DALTON%NO_MMFILES
WRITE(LUN) DALTON%MM_NO_ONE
WRITE(LUN) DALTON%CREATED_MMFILES
WRITE(LUN) DALTON%USEBUFMM
WRITE(LUN) DALTON%ATOMBASIS
WRITE(LUN) DALTON%BASIS
WRITE(LUN) DALTON%AUXBASIS
WRITE(LUN) DALTON%CABSBASIS
WRITE(LUN) DALTON%JKBASIS
WRITE(LUN) DALTON%NOFAMILY
WRITE(LUN) DALTON%Hermiteecoeff
WRITE(LUN) DALTON%DoSpherical
WRITE(LUN) DALTON%UNCONT
WRITE(LUN) DALTON%NOSEGMENT
WRITE(LUN) DALTON%DO3CENTEROVL
WRITE(LUN) DALTON%DO2CENTERERI
WRITE(LUN) DALTON%MIXEDOVERLAP
WRITE(LUN) DALTON%CS_SCREEN
WRITE(LUN) DALTON%PARI_SCREEN
WRITE(LUN) DALTON%OE_SCREEN
WRITE(LUN) DALTON%saveGABtoMem
WRITE(LUN) DALTON%PS_SCREEN
WRITE(LUN) DALTON%PS_DEBUG
WRITE(LUN) DALTON%OD_SCREEN 
WRITE(LUN) DALTON%MBIE_SCREEN
WRITE(LUN) DALTON%FRAGMENT
WRITE(LUN) DALTON%LR_EXCHANGE_DF
WRITE(LUN) DALTON%LR_EXCHANGE_PARI
WRITE(LUN) DALTON%LR_EXCHANGE
WRITE(LUN) DALTON%ADMM_EXCHANGE
WRITE(LUN) DALTON%ADMM_GCBASIS
WRITE(LUN) DALTON%ADMM_JKBASIS
WRITE(LUN) DALTON%ADMM_DFBASIS
WRITE(LUN) DALTON%ADMM_MCWEENY
WRITE(LUN) DALTON%SR_EXCHANGE
WRITE(LUN) DALTON%CAM

WRITE(LUN) DALTON%LINSCAPRINT
WRITE(LUN) DALTON%AOPRINT
WRITE(LUN) DALTON%MOLPRINT
WRITE(LUN) DALTON%INTPRINT
WRITE(LUN) DALTON%BASPRINT
WRITE(LUN) DALTON%FTUVmaxprim
WRITE(LUN) DALTON%maxpasses
WRITE(LUN) DALTON%MM_LMAX
WRITE(LUN) DALTON%MM_TLMAX
WRITE(LUN) DALTON%MMunique_ID1
WRITE(LUN) DALTON%CARMOM
WRITE(LUN) DALTON%SPHMOM
WRITE(LUN) DALTON%numAtomsPerFragment
WRITE(LUN) DALTON%LU_LUINTM
WRITE(LUN) DALTON%LU_LUINTR
WRITE(LUN) DALTON%LU_LUINDM
WRITE(LUN) DALTON%LU_LUINDR

call WRITE_DFT_PARAM(LUN,DALTON%DFT)

WRITE(LUN) DALTON%MM_SCREEN
WRITE(LUN) DALTON%DO_MMGRD
WRITE(LUN) DALTON%MM_NOSCREEN
WRITE(LUN) DALTON%THRESHOLD  
WRITE(LUN) DALTON%CS_THRESHOLD
WRITE(LUN) DALTON%OE_THRESHOLD
WRITE(LUN) DALTON%PS_THRESHOLD
WRITE(LUN) DALTON%OD_THRESHOLD
WRITE(LUN) DALTON%PARI_THRESHOLD
WRITE(LUN) DALTON%J_THR
WRITE(LUN) DALTON%K_THR
WRITE(LUN) DALTON%ONEEL_THR
WRITE(LUN) DALTON%CAMalpha
WRITE(LUN) DALTON%CAMbeta
WRITE(LUN) DALTON%CAMmu
WRITE(LUN) DALTON%exchangeFactor

END SUBROUTINE write_daltonitem_to_disk

!> \brief read daltonitem from disk
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lun logical unit number to write to
!> \param dalton the daltonitem structure
SUBROUTINE read_daltonitem_from_disk(lun,DALTON)
implicit none
TYPE(integralconfig),intent(inout)   :: DALTON
INTEGER,intent(in)            :: lun

READ(LUN) DALTON%CONTANG
READ(LUN) DALTON%NOGCINTEGRALTRANSFORM
READ(LUN) DALTON%NOBQBQ
READ(LUN) DALTON%NOOMP
READ(LUN) DALTON%UNRES
READ(LUN) DALTON%CFG_LSDALTON
READ(LUN) DALTON%TRILEVEL
READ(LUN) DALTON%DOPASS
READ(LUN) DALTON%DENSFIT
READ(LUN) DALTON%DF_K
READ(LUN) DALTON%INTEREST
READ(LUN) DALTON%MATRICESINMEMORY
READ(LUN) DALTON%MEMDIST
READ(LUN) DALTON%LOW_ACCURACY_START
READ(LUN) DALTON%LINSCA
READ(LUN) DALTON%PRINTATOMCOORD
READ(LUN) DALTON%JENGINE
READ(LUN) DALTON%LOCALLINK
READ(LUN) DALTON%LOCALLINKmulthr
READ(LUN) DALTON%LOCALLINKsimmul
READ(LUN) DALTON%LOCALLINKoption
READ(LUN) DALTON%LOCALLINKincrem
READ(LUN) DALTON%LOCALLINKDcont
READ(LUN) DALTON%LOCALLINKDthr
READ(LUN) DALTON%FMM
READ(LUN) DALTON%LINK
READ(LUN) DALTON%LSDASCREEN
READ(LUN) DALTON%LSDAJENGINE
READ(LUN) DALTON%LSDACOULOMB
READ(LUN) DALTON%LSDALINK
READ(LUN) DALTON%LSDASCREEN_THRLOG
READ(LUN) DALTON%DAJENGINE
READ(LUN) DALTON%DACOULOMB
READ(LUN) DALTON%DALINK
READ(LUN) DALTON%DASCREEN_THRLOG
READ(LUN) DALTON%DEBUGOVERLAP
READ(LUN) DALTON%DEBUG4CENTER
READ(LUN) DALTON%DEBUGPROP
READ(LUN) DALTON%DEBUGGEN1INT
READ(LUN) DALTON%DEBUGCGTODIFF
READ(LUN) DALTON%DEBUGEP
READ(LUN) DALTON%DEBUGscreen
READ(LUN) DALTON%DEBUGGEODERIVOVERLAP
READ(LUN) DALTON%DEBUGGEODERIVKINETIC
READ(LUN) DALTON%DEBUGGEODERIVEXCHANGE
READ(LUN) DALTON%DEBUGGEODERIVCOULOMB
READ(LUN) DALTON%DEBUGMAGDERIV
READ(LUN) DALTON%DEBUGMAGDERIVOVERLAP
READ(LUN) DALTON%DEBUG4CENTER_ERI
READ(LUN) DALTON%DEBUGCCFRAGMENT
READ(LUN) DALTON%DEBUGKINETIC
READ(LUN) DALTON%DEBUGNUCPOT
READ(LUN) DALTON%DO4CENTERERI
READ(LUN) DALTON%OVERLAP_DF_J
READ(LUN) DALTON%DEBUGGGEM
READ(LUN) DALTON%DEBUGLSlib
READ(LUN) DALTON%DEBUGUncontAObatch
READ(LUN) DALTON%DEBUGDECPACKED
READ(LUN) DALTON%PARI_J
READ(LUN) DALTON%PARI_K
READ(LUN) DALTON%SIMPLE_PARI
READ(LUN) DALTON%NON_ROBUST_PARI
READ(LUN) DALTON%PARI_CHARGE
READ(LUN) DALTON%PARI_DIPOLE
READ(LUN) DALTON%TIMINGS
READ(LUN) DALTON%nonSphericalETUV
READ(LUN) DALTON%HIGH_RJ000_ACCURACY
READ(LUN) DALTON%NO_MMFILES
READ(LUN) DALTON%MM_NO_ONE
READ(LUN) DALTON%CREATED_MMFILES
READ(LUN) DALTON%USEBUFMM
READ(LUN) DALTON%ATOMBASIS
READ(LUN) DALTON%BASIS
READ(LUN) DALTON%AUXBASIS
READ(LUN) DALTON%CABSBASIS
READ(LUN) DALTON%JKBASIS
READ(LUN) DALTON%NOFAMILY
READ(LUN) DALTON%Hermiteecoeff
READ(LUN) DALTON%DoSpherical
READ(LUN) DALTON%UNCONT
READ(LUN) DALTON%NOSEGMENT
READ(LUN) DALTON%DO3CENTEROVL
READ(LUN) DALTON%DO2CENTERERI
READ(LUN) DALTON%MIXEDOVERLAP
READ(LUN) DALTON%CS_SCREEN
READ(LUN) DALTON%PARI_SCREEN
READ(LUN) DALTON%OE_SCREEN
READ(LUN) DALTON%saveGABtoMem
READ(LUN) DALTON%PS_SCREEN
READ(LUN) DALTON%PS_DEBUG
READ(LUN) DALTON%OD_SCREEN 
READ(LUN) DALTON%MBIE_SCREEN
READ(LUN) DALTON%FRAGMENT
READ(LUN) DALTON%LR_EXCHANGE_DF
READ(LUN) DALTON%LR_EXCHANGE_PARI
READ(LUN) DALTON%LR_EXCHANGE
READ(LUN) DALTON%ADMM_EXCHANGE
READ(LUN) DALTON%ADMM_GCBASIS
READ(LUN) DALTON%ADMM_JKBASIS
READ(LUN) DALTON%ADMM_DFBASIS
READ(LUN) DALTON%ADMM_MCWEENY
READ(LUN) DALTON%SR_EXCHANGE
READ(LUN) DALTON%CAM

READ(LUN) DALTON%LINSCAPRINT
READ(LUN) DALTON%AOPRINT
READ(LUN) DALTON%MOLPRINT
READ(LUN) DALTON%INTPRINT
READ(LUN) DALTON%BASPRINT
READ(LUN) DALTON%FTUVmaxprim
READ(LUN) DALTON%maxpasses
READ(LUN) DALTON%MM_LMAX
READ(LUN) DALTON%MM_TLMAX
READ(LUN) DALTON%MMunique_ID1
READ(LUN) DALTON%CARMOM
READ(LUN) DALTON%SPHMOM
READ(LUN) DALTON%numAtomsPerFragment
READ(LUN) DALTON%LU_LUINTM
READ(LUN) DALTON%LU_LUINTR
READ(LUN) DALTON%LU_LUINDM
READ(LUN) DALTON%LU_LUINDR

call READ_DFT_PARAM(LUN,DALTON%DFT)

READ(LUN) DALTON%MM_SCREEN
READ(LUN) DALTON%DO_MMGRD
READ(LUN) DALTON%MM_NOSCREEN
READ(LUN) DALTON%THRESHOLD  
READ(LUN) DALTON%CS_THRESHOLD
READ(LUN) DALTON%OE_THRESHOLD
READ(LUN) DALTON%PS_THRESHOLD
READ(LUN) DALTON%OD_THRESHOLD
READ(LUN) DALTON%PARI_THRESHOLD
READ(LUN) DALTON%J_THR
READ(LUN) DALTON%K_THR
READ(LUN) DALTON%ONEEL_THR
READ(LUN) DALTON%CAMalpha
READ(LUN) DALTON%CAMbeta
READ(LUN) DALTON%CAMmu
READ(LUN) DALTON%exchangeFactor

END SUBROUTINE read_daltonitem_from_disk
#endif

!> \brief set the integralconfig to default values
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param dalton the integralconfig structure
SUBROUTINE integral_set_default_config(DALTON)
IMPLICIT NONE
TYPE(integralconfig)   :: DALTON

DALTON%CONTANG=.FALSE. !Default order is angular components first, contracted functions second
DALTON%NOGCINTEGRALTRANSFORM=.FALSE. !we do trans if segmentet basis
DALTON%FORCEGCBASIS=.FALSE. !we do trans if segmentet basis
DALTON%NOBQBQ = .FALSE.
DALTON%noomp = .FALSE.
DALTON%unres = .FALSE.
DALTON%cfg_lsdalton = .FALSE.
DALTON%TRILEVEL = .TRUE.
DALTON%DOPASS = .TRUE.
DALTON%DENSFIT = .FALSE.
DALTON%DF_K = .FALSE.
DALTON%INTEREST = .FALSE.
#ifdef VAR_SCALAPACK
DALTON%MATRICESINMEMORY = .TRUE.
#else
DALTON%MATRICESINMEMORY = .TRUE.!.FALSE.
#endif
DALTON%MEMDIST = .FALSE.
DALTON%LOW_ACCURACY_START = .FALSE.
DALTON%LINSCA = .FALSE.
!PRINTING KEYWORDS
DALTON%LINSCAPRINT = 0
DALTON%BASPRINT = 0
DALTON%AOPRINT = 0
DALTON%MOLPRINT = 0
DALTON%INTPRINT = 0
DALTON%PRINTATOMCOORD = .FALSE.
DALTON%BASIS = .FALSE.
DALTON%ATOMBASIS = .FALSE.
DALTON%AUXBASIS = .FALSE.
DALTON%CABSBASIS = .FALSE.
DALTON%JKBASIS = .FALSE.
DALTON%ADMM_EXCHANGE = .FALSE.
DALTON%ADMM_GCBASIS = .FALSE.
DALTON%ADMM_DFBASIS = .FALSE.
DALTON%ADMM_JKBASIS = .FALSE.
DALTON%ADMM_MCWEENY = .FALSE.
DALTON%NOFAMILY = .FALSE.
DALTON%Hermiteecoeff = .TRUE.
DALTON%JENGINE = .TRUE.
DALTON%LOCALLINK = .FALSE.
DALTON%LOCALLINKmulthr = 1E-5_realk
DALTON%LOCALLINKsimmul = .FALSE.
DALTON%LOCALLINKoption = 1
DALTON%LOCALLINKincrem = .FALSE.
DALTON%LOCALLINKDcont = .FALSE.
DALTON%LOCALLINKDthr = 1E-10_realk
DALTON%LINK = .TRUE.
DALTON%LSDASCREEN = .TRUE.
DALTON%LSDAJENGINE = .TRUE.
DALTON%LSDACOULOMB = .FALSE.
DALTON%LSDALINK = .TRUE.
DALTON%LSDASCREEN_THRLOG = 0 
DALTON%DAJENGINE = .FALSE.
DALTON%DACOULOMB = .FALSE.
DALTON%DALINK = .FALSE.
DALTON%DASCREEN_THRLOG = 2 !tighten with a factor 100
DALTON%HIGH_RJ000_ACCURACY = .TRUE.
!FMM PARAMETERS
DALTON%FMM = .FALSE.
DALTON%FTUVmaxprim = 64
DALTON%maxpasses = 40
DALTON%MM_LMAX   = 8
DALTON%MM_TLMAX  = 20
DALTON%MM_NO_ONE = .FALSE.
DALTON%NO_MMFILES = .FALSE.
DALTON%CREATED_MMFILES = .FALSE.
DALTON%USEBUFMM = .TRUE.
DALTON%nonSphericalETUV = .FALSE.
DALTON%DEBUGOVERLAP = .FALSE.
DALTON%DEBUG4CENTER = .FALSE.
DALTON%DEBUGPROP = .FALSE.
DALTON%DEBUGGEN1INT = .FALSE.
DALTON%DEBUGCGTODIFF = .FALSE.
DALTON%DEBUGEP = .FALSE.
DALTON%DEBUGscreen = .FALSE.
DALTON%DEBUGGEODERIVOVERLAP = .FALSE.
DALTON%DEBUGGEODERIVKINETIC = .FALSE.
DALTON%DEBUGGEODERIVEXCHANGE = .FALSE.
DALTON%DEBUGGEODERIVCOULOMB = .FALSE.
DALTON%DEBUGMAGDERIV = .FALSE.
DALTON%DEBUGMAGDERIVOVERLAP = .FALSE.
DALTON%DEBUG4CENTER_ERI = .FALSE.
DALTON%DEBUGCCFRAGMENT = .FALSE.
DALTON%DEBUGNUCPOT = .FALSE.
DALTON%DO3CENTEROVL = .FALSE.
DALTON%DO2CENTERERI = .FALSE.
DALTON%DO4CENTERERI = .FALSE.
DALTON%OVERLAP_DF_J = .FALSE.
DALTON%DEBUGGGEM = .FALSE.
DALTON%DEBUGLSlib = .FALSE.
DALTON%DEBUGUncontAObatch = .FALSE.
DALTON%DEBUGDECPACKED = .FALSE.
DALTON%PARI_J = .FALSE.
DALTON%PARI_K = .FALSE.
DALTON%SIMPLE_PARI = .FALSE.
DALTON%NON_ROBUST_PARI = .FALSE.
DALTON%PARI_CHARGE = .FALSE.
DALTON%PARI_DIPOLE = .TRUE.
DALTON%DO_MMGRD     = .FALSE.
DALTON%MM_NOSCREEN  = .FALSE.
DALTON%TIMINGS = .FALSE.
DALTON%UNCONT = .FALSE.
DALTON%NOSEGMENT = .FALSE.!.TRUE.
!=======================================================
! THE ONE THRESHOLD
!=======================================================
DALTON%THRESHOLD = 1.0E-8_realk    !target accuracy in energy
!=======================================================
! THE CONTRIBUTION THRESHOLDS:
! DALTON%J_THR is the threshold for coulomb in addition to "The ONE threshold"
! so the Integralthreshold used in Coulomb is
! Integralthreshold = DALTON%THRESHOLD * DALTON%J_THR
!=======================================================
DALTON%J_THR = 1.0E-2_realk != 1.0E-10_realk Integralthreshold 
DALTON%K_THR = 1.0E+0_realk != 1.0E-8_realk Integralthreshold 
!DALTON%J_THR and DALTON%K_THR may be modified in 
!set_final_config_and_print, depending on #elec see 
!.DYNINTTHR (which should be default)
DALTON%ONEEL_THR = 1.0E-7_realk ! so 1.0E-15_realk
!=======================================================
! The Other thresholds which is set according to the Integralthreshold 
!=======================================================
DALTON%CS_THRESHOLD = 1.0E+0_realk!1.0E-10_realk for J,K  1.0E-15_realk for oneel  
DALTON%OE_THRESHOLD = 1.0E-1_realk!1.0E-11_realk for J,K  1.0E-16_realk for oneel  
DALTON%PS_THRESHOLD = 1.0E-1_realk!1.0E-11_realk for J,K  1.0E-16_realk for oneel  
DALTON%OD_THRESHOLD = 1.0E-1_realk!1.0E-11_realk for J,K  1.0E-16_realk for oneel  
DALTON%PARI_THRESHOLD = 1.0E-4_realk! so 1.0E-14_realk ...
DALTON%MM_SCREEN    = 1.0E-1_realk!1.0E-11_realk for J,K  1.0E-16_realk for oneel  

DALTON%CS_SCREEN = .TRUE.
DALTON%PARI_SCREEN = .TRUE.
DALTON%OE_SCREEN = .TRUE.

DALTON%saveGABtoMem = .TRUE.
DALTON%PS_SCREEN = .TRUE.
DALTON%OD_SCREEN = .TRUE.

DALTON%MBIE_SCREEN = .FALSE.!.TRUE. For now it is turned off, until fully testet
DALTON%PS_DEBUG = .FALSE.
DALTON%DEBUGKINETIC = .FALSE.
DALTON%CARMOM = 0
DALTON%SPHMOM = 0
!DALTON%FRAGMENT = .TRUE.
DALTON%FRAGMENT = .FALSE.
!Default is to make the number of atoms so large fragmentation is not used
DALTON%numAtomsPerFragment = 10000000
DALTON%MIXEDOVERLAP = .FALSE.

DALTON%LR_EXCHANGE_DF = .FALSE.
DALTON%LR_EXCHANGE_PARI = .FALSE.
DALTON%LR_EXCHANGE = .FALSE.
DALTON%ADMM_EXCHANGE = .FALSE.
DALTON%ADMM_GCBASIS    = .FALSE.
DALTON%ADMM_JKBASIS    = .FALSE.
DALTON%ADMM_DFBASIS    = .FALSE.
DALTON%ADMM_MCWEENY    = .FALSE.
!CAM PARAMETERS
DALTON%SR_EXCHANGE = .FALSE.
DALTON%CAM = .FALSE.
DALTON%CAMalpha=0.19E0_realk
DALTON%CAMbeta=0.46E0_realk
DALTON%CAMmu=0.33E0_realk

!DFT PARAMETERS
CALL DFT_set_default_config(DALTON%DFT)

! DEC TEST PARAMETERS
DALTON%run_dec_gradient_test=.false.
END SUBROUTINE integral_set_default_config

!!$!> \brief attach dmat to integral input structure
!!$!> \author S. Reine and T. Kjaergaard
!!$!> \date 2010
!!$!> \param integralinput the integral input structure
!!$!> \param Dmat to attach
!!$!> \param ndim1 size of dimension 1
!!$!> \param ndim2 size of dimension 2
!!$!> \param ndmat number of density matrices
!!$!> \param Dmatside the side of the matrix LHS or RHS
!!$SUBROUTINE attachDmatToInput(Input,Dmat,ndim1,ndim2,ndmat,DmatSide)
!!$implicit none
!!$Type(IntegralInput) :: Input
!!$Integer             :: ndim1,ndim2,ndmat
!!$Real(realk),target  :: Dmat(ndim1,ndim2,ndmat)
!!$Character(3)        :: DmatSide
!!$IF (DmatSide.EQ.'LHS') THEN
!!$  Input%LHS_DMAT     = .TRUE.
!!$  Input%DMAT_LHS     => Dmat
!!$  Input%NDMAT_LHS    = ndmat
!!$  Input%NDIM_LHS(1)  = ndim1
!!$  Input%NDIM_LHS(2)  = ndim2
!!$ELSE IF (DmatSide.EQ.'RHS') THEN
!!$  Input%RHS_DMAT     = .TRUE.
!!$  Input%DMAT_RHS     => Dmat
!!$  Input%NDMAT_RHS    = ndmat
!!$  Input%NDIM_RHS(1)  = ndim1
!!$  Input%NDIM_RHS(2)  = ndim2
!!$ELSE
!!$  CALL LSQUIT('Programming error: attachDmatToInput called with wrong argument',-1)
!!$ENDIF
!!$END SUBROUTINE attachDmatToInput

!*****************************************
!*
!*  AOBATCH INITIATION ROUTINES
!*
!*****************************************

!> \brief print lsitem 
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param LS the lsitem
!> \param lupri the logical unit number to write to
SUBROUTINE PRINT_LSITEM(LS,LUPRI)
IMPLICIT NONE
TYPE(LSITEM) :: LS
INTEGER      :: LUPRI

CALL PRINT_DALTONINPUT(LS%INPUT,LUPRI)
CALL PRINT_LSSETTING(LS%SETTING,LUPRI)

END SUBROUTINE PRINT_LSITEM

!> \brief print the dalton input structure
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param dalton the dalton input
!> \param lupri the logical unit number to write to
SUBROUTINE PRINT_DALTONINPUT(DALTON,LUPRI)
IMPLICIT NONE
TYPE(DALTONINPUT) :: DALTON
INTEGER           :: LUPRI

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE DALTON INPUT STUCTUR'
WRITE(LUPRI,*) '                     '
CALL PRINT_MOLECULEINFO(LUPRI,DALTON%MOLECULE,DALTON%BASIS,DALTON%DALTON%MOLPRINT)
CALL PRINT_MOLECULE_AND_BASIS(LUPRI,DALTON%MOLECULE,DALTON%BASIS%REGULAR)
CALL PRINT_BASISSETINFO(LUPRI,DALTON%BASIS%REGULAR)
CALL PRINT_DALTONITEM(LUPRI,DALTON%DALTON)
CALL PRINT_IOITEM(DALTON%IO,LUPRI)

IF(DALTON%DALTON%AUXBASIS)THEN
   write(lupri,*)'THE DALTON%BASIS%AUXILIARY'
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,DALTON%MOLECULE,DALTON%BASIS%AUXILIARY)
   CALL PRINT_BASISSETINFO(LUPRI,DALTON%BASIS%AUXILIARY)
ENDIF

IF(DALTON%DALTON%CABSBASIS)THEN
   write(lupri,*)'THE DALTON%BASIS%CABS'
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,DALTON%MOLECULE,DALTON%BASIS%CABS)
   CALL PRINT_BASISSETINFO(LUPRI,DALTON%BASIS%CABS)
ENDIF

IF(DALTON%DALTON%JKBASIS)THEN
   write(lupri,*)'THE DALTON%BASIS%JK'
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,DALTON%MOLECULE,DALTON%BASIS%JK)
   CALL PRINT_BASISSETINFO(LUPRI,DALTON%BASIS%JK)
ENDIF

END SUBROUTINE PRINT_DALTONINPUT

!> \brief print the lssetting 
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param set the lssetting structure
!> \param lupri the logical unit number to write to
SUBROUTINE PRINT_LSSETTING(SET,LUPRI)
IMPLICIT NONE
TYPE(LSSETTING) :: SET
INTEGER         :: LUPRI
!
INTEGER :: I,J,dim1,dim2,nrow,ncol,imat

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE SETTING STUCTUR'
WRITE(LUPRI,*) '                     '
WRITE(LUPRI,*)'Transform between AO and GCAO ?',SET%IntegralTransformGC
WRITE(LUPRI,*)'MPI comm',SET%comm
WRITE(LUPRI,*)'DO_DFT',SET%DO_DFT
WRITE(LUPRI,*)'EDISP',SET%EDISP
WRITE(LUPRI,*)'nAO:',SET%nAO
DO I=1,SET%nAO
   WRITE(LUPRI,*)'AO NUMBER',I
   WRITE(LUPRI,*)'MOLECULE AND BASIS'
   CALL PRINT_MOLECULEINFO(LUPRI,SET%MOLECULE(I)%p,SET%BASIS(I)%p,1)
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,SET%MOLECULE(I)%p,SET%BASIS(I)%p%REGULAR)   
   CALL PRINT_BASISSETINFO(LUPRI,SET%BASIS(I)%p%REGULAR)
   WRITE(LUPRI,*)'FRAGMENT AND BASIS'
   CALL PRINT_MOLECULEINFO(LUPRI,SET%FRAGMENT(I)%p,SET%BASIS(I)%p,1)
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,SET%FRAGMENT(I)%p,SET%BASIS(I)%p%REGULAR)   
   WRITE(LUPRI,*)'Batchindex(',I,')=',SET%Batchindex(I)
   WRITE(LUPRI,*)'Batchsize(',I,')=',SET%Batchsize(I)
   WRITE(LUPRI,*)'Batchdim  (',I,')=',SET%Batchdim(I)
   WRITE(LUPRI,*)'molID     (',I,')=',SET%molID(I)
   WRITE(LUPRI,*)'molBuild  (',I,')=',SET%molBUILD(I)
   WRITE(LUPRI,*)'basBuild  (',I,')=',SET%basBUILD(I)
   WRITE(LUPRI,*)'fragBuild  (',I,')=',SET%fragBUILD(I)
ENDDO
WRITE(LUPRI,*)'THE LSINTSCHEM'
call typedef_printScheme(SET%SCHEME,LUPRI)
WRITE(LUPRI,*)'THE IO'
CALL PRINT_IOITEM(SET%IO,LUPRI)
DO I=1,SET%nAO
   WRITE(LUPRI,*)'SameMol ',(SET%SameMol(I,J),J=1,SET%nAO)
ENDDO
DO I=1,SET%nAO
   WRITE(LUPRI,*)'SameBas ',(SET%Samebas(I,J),J=1,SET%nAO)
ENDDO
DO I=1,SET%nAO
   WRITE(LUPRI,*)'SameFrag',(SET%SameFrag(I,J),J=1,SET%nAO)
ENDDO

IF(SET%RHSdmat)THEN
   DO imat = 1,SET%nDmatRHS
      nrow = SET%DmatRHS(Imat)%p%nrow
      ncol = SET%DmatRHS(Imat)%p%ncol
      WRITE(LUPRI,*)'THE RHS DENSITY TYPE(MATRIX) NR=',Imat,'Dim=',nrow,ncol,'Sym=',SET%DsymRHS(Imat)
      call mat_print(SET%DmatRHS(Imat)%p,1,nrow,1,ncol,lupri)
   enddo
ELSE
   WRITE(lupri,*)'RHSdmat',SET%RHSdmat
ENDIF
IF(SET%RHSdfull)THEN
   WRITE(lupri,*)'RHSdalloc',SET%RHSdalloc
   dim1 = SIZE(SET%DfullRHS, 1)  
   dim2 = SIZE(SET%DfullRHS, 2)  
   DO imat = 1,SET%nDmatRHS
      WRITE(LUPRI,*)'THE RHS DENSITY REAL(REALK) NR=',Imat,'Dim=',dim1,dim2,'Sym=',SET%DsymRHS(Imat)
      call output(SET%DfullRHS(:,:,imat),1,dim1,1,dim2,dim1,dim2,1,lupri)
   ENDDO
ELSE
   WRITE(lupri,*)'RHSdfull',SET%RHSdfull
   WRITE(lupri,*)'RHSdalloc',SET%RHSdalloc
ENDIF
IF(SET%LHSdmat)THEN
   DO imat = 1,SET%nDmatLHS
      nrow = SET%DmatLHS(Imat)%p%nrow
      ncol = SET%DmatLHS(Imat)%p%ncol
      WRITE(LUPRI,*)'THE RHS DENSITY TYPE(MATRIX) NR=',Imat,'Dim=',nrow,ncol,'Sym=',SET%DsymLHS(Imat)
      call mat_print(SET%DmatLHS(Imat)%p,1,nrow,1,ncol,lupri)
   enddo
ELSE
   WRITE(lupri,*)'LHSdmat',SET%LHSdmat
ENDIF
IF(SET%LHSdfull)THEN
   WRITE(lupri,*)'LHSdalloc',SET%LHSdalloc
   dim1 = SIZE(SET%DfullLHS, 1)  
   dim2 = SIZE(SET%DfullLHS, 2)  
   DO imat = 1,SET%nDmatLHS
      WRITE(LUPRI,*)'THE RHS DENSITY REAL(REALK) NR=',Imat,'Dim=',dim1,dim2,'Sym=',SET%DsymLHS(Imat)
      call output(SET%DfullLHS(:,:,imat),1,dim1,1,dim2,dim1,dim2,1,lupri)
   ENDDO
ELSE
   WRITE(lupri,*)'LHSdfull',SET%LHSdfull
   WRITE(lupri,*)'LHSdalloc',SET%LHSdalloc
ENDIF

WRITE(lupri,*)'lstensor_attached',SET%lstensor_attached    !LSSETTING029
IF (SET%lstensor_attached) THEN
  IF (ASSOCIATED(SET%lst_dLHS)) THEN
    WRITE(lupri,*) 'Printing lst_dLHS'
    call lstensor_print(SET%lst_dLHS,lupri)
  ELSE
    WRITE(lupri,*) 'The lst_dLHS is not associated'
  ENDIF
  IF (ASSOCIATED(SET%lst_dRHS)) THEN
    WRITE(lupri,*) 'Printing lst_dRHS'
    call lstensor_print(SET%lst_dRHS,lupri)
  ELSE
    WRITE(lupri,*) 'The lst_dRHS is not associated'
  ENDIF
ENDIF


WRITE(LUPRI,*)'LHSdmatAOindex1',SET%LHSdmatAOindex1
WRITE(LUPRI,*)'LHSdmatAOindex2',SET%LHSdmatAOindex2
WRITE(LUPRI,*)'RHSdmatAOindex1',SET%RHSdmatAOindex1
WRITE(LUPRI,*)'RHSdmatAOindex2',SET%RHSdmatAOindex2

WRITE(LUPRI,*)'numFragments',SET%numFragments
WRITE(LUPRI,*)'numNodes    ',SET%numNodes
WRITE(LUPRI,*)'node        ',SET%node

!missing is FRAGMENTITEM,INTEGRALOUTPUT,GAussianGeminal

END SUBROUTINE PRINT_LSSETTING

!> \brief print the moleculeinfo structure
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param molecule the molecule info structure
!> \param basis the basis info structure
SUBROUTINE PRINT_MOLECULEINFO(LUPRI,MOLECULE,BASIS,IPRINT)
implicit none
TYPE(MOLECULEINFO) :: MOLECULE
TYPE(BASISINFO)    :: BASIS
INTEGER            :: I,J,IPRINT
INTEGER            :: LUPRI,ICHARGE,ITYPE1,ITYPE2

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE MOLECULE'

WRITE(LUPRI,*) '--------------------------------------------------------------------'
WRITE(LUPRI,'(A38,2X,F8.4)')'Molecular Charge                    :',MOLECULE%charge
WRITE(LUPRI,'(2X,A38,2X,I7)')'Regular basisfunctions             :',MOLECULE%nbastREG
WRITE(LUPRI,'(2X,A38,2X,I7)')'Auxiliary basisfunctions           :',MOLECULE%nbastAUX
WRITE(LUPRI,'(2X,A38,2X,I7)')'CABS basisfunctions                :',MOLECULE%nbastCABS
WRITE(LUPRI,'(2X,A38,2X,I7)')'JK-fit basisfunctions              :',MOLECULE%nbastJK
WRITE(LUPRI,'(2X,A38,2X,I7)')'Valence basisfunctions             :',MOLECULE%nbastVAL
WRITE(LUPRI,'(2X,A38,2X,I7)')'Primitive Regular basisfunctions   :',MOLECULE%nprimbastREG
WRITE(LUPRI,'(2X,A38,2X,I7)')'Primitive Auxiliary basisfunctions :',MOLECULE%nprimbastAUX
WRITE(LUPRI,'(2X,A38,2X,I7)')'Primitive CABS basisfunctions      :',MOLECULE%nprimbastCABS
WRITE(LUPRI,'(2X,A38,2X,I7)')'Primitive JK-fit basisfunctions    :',MOLECULE%nprimbastJK
WRITE(LUPRI,'(2X,A38,2X,I7)')'Primitive Valence basisfunctions   :',MOLECULE%nprimbastVAL
WRITE(LUPRI,*) '--------------------------------------------------------------------'
WRITE(LUPRI,*) '                     '

WRITE(LUPRI,*) '                     '
IF(MOLECULE%ATOM(1)%nbasis == 2) THEN
   WRITE(LUPRI,*) '--------------------------------------------------------------------'
   WRITE(LUPRI,'(2X,A4,2X,A6,2X,A12,2X,A20,2X,A9,2X,A8,2X,A8)')'atom',&
        &'charge','Atomicbasis ','Auxiliarybasisset',' Phantom ','nPrimREG','nContREG'
   WRITE(LUPRI,*) '--------------------------------------------------------------------'
ELSE
   WRITE(LUPRI,*) '--------------------------------------------------------------------'
   WRITE(LUPRI,'(2X,A4,2X,A6,2X,A12,2X,A9,2X,A8,2X,A8)')'atom',&
        &'charge','Atomicbasis ',' Phantom ','nPrimREG','nContREG'
   WRITE(LUPRI,*) '--------------------------------------------------------------------'
ENDIF

IF(MOLECULE%nAtoms .GT. 30)THEN
   IF(BASIS%REGULAR%Labelindex .EQ. 0)THEN
      DO I=1,30
         IF(MOLECULE%ATOM(I)%nbasis == 2) THEN
            ICHARGE = NINT(MOLECULE%ATOM(I)%CHARGE)
            ITYPE1 = BASIS%REGULAR%CHARGEINDEX(ICHARGE)
            ITYPE2 = BASIS%AUXILIARY%CHARGEINDEX(ICHARGE)
            WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                 &BASIS%REGULAR%ATOMTYPE(ITYPE1)%NAME,&
                 &BASIS%AUXILIARY%ATOMTYPE(ITYPE2)%NAME,&
                 &MOLECULE%ATOM(I)%Phantom,&
                 &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
         ELSE
            ICHARGE = NINT(MOLECULE%ATOM(I)%CHARGE)
            ITYPE1 = BASIS%REGULAR%CHARGEINDEX(ICHARGE)
            WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                 &BASIS%REGULAR%ATOMTYPE(ITYPE1)%NAME,&
                 &MOLECULE%ATOM(I)%Phantom,&
                 &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
         ENDIF
      ENDDO
      WRITE(LUPRI,'(2X,A)')'Since you have more than 30 atoms only the first 30'
      WRITE(LUPRI,'(2X,A)')'are printed in order to limit output'
   ELSE
      DO I=1,30
         IF(MOLECULE%ATOM(I)%nbasis == 2) THEN
            ITYPE1 = MOLECULE%ATOM(I)%IDtype(1)
            ITYPE2 = MOLECULE%ATOM(I)%IDtype(2)
            WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                 &BASIS%REGULAR%ATOMTYPE(ITYPE1)%NAME,&
                 &BASIS%AUXILIARY%ATOMTYPE(ITYPE2)%NAME,&
                 &MOLECULE%ATOM(I)%Phantom,&
                 &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
         ELSE
            ITYPE1 = MOLECULE%ATOM(I)%IDtype(1)
            WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                 &BASIS%REGULAR%ATOMTYPE(ITYPE1)%NAME,&
                 &MOLECULE%ATOM(I)%Phantom,&
                 &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
         ENDIF
      ENDDO
      WRITE(LUPRI,'(2X,A)')'Since you have more than 30 atoms only the first 30'
      WRITE(LUPRI,'(2X,A)')'are printed in order to limit output'
   ENDIF
ELSE
   IF(BASIS%REGULAR%Labelindex .EQ. 0)THEN
      DO I=1,MOLECULE%nAtoms
         IF(MOLECULE%ATOM(I)%nbasis == 2) THEN
            ICHARGE = INT(MOLECULE%ATOM(I)%CHARGE)
            ITYPE1 = BASIS%REGULAR%CHARGEINDEX(ICHARGE)
            ITYPE2 = BASIS%AUXILIARY%CHARGEINDEX(ICHARGE)
            IF(.NOT.MOLECULE%ATOM(I)%Pointcharge)THEN
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &BASIS%REGULAR%ATOMTYPE(itype1)%NAME,&
                    &BASIS%AUXILIARY%ATOMTYPE(itype2)%NAME,&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ELSE
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &'Pointcharge',' ',MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ENDIF
         ELSE
            ICHARGE = INT(MOLECULE%ATOM(I)%CHARGE)
            ITYPE1 = BASIS%REGULAR%CHARGEINDEX(ICHARGE)
            IF(.NOT.MOLECULE%ATOM(I)%Pointcharge)THEN
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &BASIS%REGULAR%ATOMTYPE(itype1)%NAME,&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ELSE
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &'Pointcharge',&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ENDIF
         ENDIF
      ENDDO
   ELSE
      DO I=1,MOLECULE%nAtoms
         IF(MOLECULE%ATOM(I)%nbasis == 2) THEN
            ITYPE1 = MOLECULE%ATOM(I)%IDtype(1)
            ITYPE2 = MOLECULE%ATOM(I)%IDtype(2)
            IF(.NOT.MOLECULE%ATOM(I)%Pointcharge)THEN
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &BASIS%REGULAR%ATOMTYPE(itype1)%NAME,&
                    &BASIS%AUXILIARY%ATOMTYPE(itype2)%NAME,&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ELSE
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,2X,A20,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &'Pointcharge',' ',MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ENDIF
         ELSE
            ITYPE1 = MOLECULE%ATOM(I)%IDtype(1)
            IF(.NOT.MOLECULE%ATOM(I)%Pointcharge)THEN
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &BASIS%REGULAR%ATOMTYPE(itype1)%NAME,&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ELSE
               WRITE(LUPRI,'(2X,I4,2X,F6.3,2X,A12,4X,L1,10X,I5,7X,I5)') I,MOLECULE%ATOM(I)%Charge,&
                    &'Pointcharge',&
                    &MOLECULE%ATOM(I)%Phantom,&
                    &MOLECULE%ATOM(I)%nPrimOrbREG,MOLECULE%ATOM(I)%nContOrbREG
            ENDIF
         ENDIF
      ENDDO
   ENDIF
ENDIF

WRITE(LUPRI,*) '                     '

WRITE(LUPRI,*)'The cartesian centers in Atomic units. '
WRITE(LUPRI,'(2X,A4,2X,A4,2X,A7,2X,A16,2X,A16,2X,A16)')'ATOM','NAME',&
     &'ISOTOPE','      X     ','      Y     ','      Z     '
IF(MOLECULE%nAtoms .LT. 30.OR.IPRINT.GT.0)THEN
   DO I=1,MOLECULE%nAtoms
      WRITE(LUPRI,'(2X,I4,2X,A4,2X,I7,2X,F16.8,2X,F16.8,2X,F16.8)') I,&
           & MOLECULE%ATOM(I)%Name,&
           & MOLECULE%ATOM(I)%Isotope,&
           & MOLECULE%ATOM(I)%CENTER(1),&
           & MOLECULE%ATOM(I)%CENTER(2),&
           & MOLECULE%ATOM(I)%CENTER(3)
   ENDDO
ELSE
   DO I=1,30
      WRITE(LUPRI,'(2X,I4,2X,A4,2X,I7,2X,F16.8,2X,F16.8,2X,F16.8)') I,&
           & MOLECULE%ATOM(I)%Name,&
           & MOLECULE%ATOM(I)%Isotope,&
           & MOLECULE%ATOM(I)%CENTER(1),&
           & MOLECULE%ATOM(I)%CENTER(2),&
           & MOLECULE%ATOM(I)%CENTER(3)
   ENDDO
   WRITE(LUPRI,'(2X,A)')'Since you have more than 30 atoms only the first 30'
   WRITE(LUPRI,'(2X,A)')'are printed in order to limit output'
   WRITE(LUPRI,'(2X,A)')'to force full printout use'
   WRITE(LUPRI,'(2X,A)')'.MOLPRINT'
   WRITE(LUPRI,'(2X,A)')'1'
   WRITE(LUPRI,'(2X,A)')'under **INTEGRALS in DALTON.INP'
ENDIF

WRITE(LUPRI,*) '                     '

END SUBROUTINE PRINT_MOLECULEINFO

!> \brief PRINT BASISSETLIBRARY
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param basissetlibrary
SUBROUTINE PRINT_BASISSETLIBRARY(LUPRI,BASISSETLIBRARY)
implicit none
TYPE(BASISSETLIBRARYITEM) :: BASISSETLIBRARY
INTEGER            :: I,J
INTEGER            :: LUPRI
CHARACTER(len=13)   :: STRINGFORMAT
WRITE(LUPRI,*) '  '
WRITE(LUPRI,'(A)')'BASISSETLIBRARY'
WRITE(LUPRI,*)'Number of Basisset',BASISSETLIBRARY%nbasissets
DO I=1,BASISSETLIBRARY%nbasissets
   WRITE(LUPRI,'(A10,2X,A50)')'BASISSET:',BASISSETLIBRARY%BASISSETNAME(I)
   IF(BASISSETLIBRARY%nCharges(I) < 10)THEN
      WRITE(StringFormat,'(A5,I1,A6)') '(A10,',BASISSETLIBRARY%nCharges(I),'F10.4)'
   ELSE
      WRITE(StringFormat,'(A5,I2,A6)') '(A10,',BASISSETLIBRARY%nCharges(I),'F10.4)'
   ENDIF
   WRITE(LUPRI,StringFormat)'CHARGES:',(BASISSETLIBRARY%Charges(I,J)&
        &,J=1,BASISSETLIBRARY%nCharges(I))
ENDDO
WRITE(LUPRI,*) '                     '

END SUBROUTINE PRINT_BASISSETLIBRARY

!> \brief PRINT the integral config structure
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param dalton the integral config structure to be printet
SUBROUTINE PRINT_DALTONITEM(LUPRI,DALTON)
implicit none
TYPE(integralconfig)  :: DALTON
INTEGER           :: LUPRI

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE DALTONITEM'
WRITE(LUPRI,*)' '
WRITE(LUPRI,'(2X,A35,7X,L1)')'CONTANG',DALTON%CONTANG
WRITE(LUPRI,'(2X,A35,7X,L1)')'NOGCINTEGRALTRANSFORM',DALTON%NOGCINTEGRALTRANSFORM
WRITE(LUPRI,'(2X,A35,7X,L1)')'DENSFIT',DALTON%DENSFIT
WRITE(LUPRI,'(2X,A35,7X,L1)')'DF_K',DALTON%DF_K
WRITE(LUPRI,'(2X,A35,7X,L1)')'INTEREST',DALTON%INTEREST
WRITE(LUPRI,'(2X,A35,7X,L1)')'MATRICESINMEMORY',DALTON%MATRICESINMEMORY
WRITE(LUPRI,'(2X,A35,7X,L1)')'MEMDIST',DALTON%MEMDIST
WRITE(LUPRI,'(2X,A35,7X,L1)')'LOW_ACCURACY_START',DALTON%LOW_ACCURACY_START
WRITE(LUPRI,'(2X,A35,7X,L1)')'LINSCA',DALTON%LINSCA
WRITE(LUPRI,'(2X,A35,I8)')'LINSCAPRINT',DALTON%LINSCAPRINT
WRITE(LUPRI,'(2X,A35,I8)')'AOPRINT',DALTON%AOPRINT
WRITE(LUPRI,'(2X,A35,I8)')'MOLPRINT',DALTON%MOLPRINT
WRITE(LUPRI,'(2X,A35,7X,L1)')'NOBQBQ',DALTON%NOBQBQ
WRITE(LUPRI,'(2X,A35,7X,L1)')'JENGINE',DALTON%JENGINE
WRITE(LUPRI,'(2X,A35,7X,L1)')'LOCALLINK',DALTON%LOCALLINK
WRITE(LUPRI,'(2X,A35,7X,F16.8)')'LOCALLINKmulthr',DALTON%LOCALLINKmulthr
WRITE(LUPRI,'(2X,A35,7X,L1)')'LOCALLINKsimmul',DALTON%LOCALLINKsimmul
WRITE(LUPRI,'(2X,A35,7X,I8)')'LOCALLINKoption',DALTON%LOCALLINKoption
WRITE(LUPRI,'(2X,A35,7X,L1)')'LOCALLINKincrem',DALTON%LOCALLINKincrem
WRITE(LUPRI,'(2X,A35,7X,L1)')'LOCALLINKcont',DALTON%LOCALLINKDcont
WRITE(LUPRI,'(2X,A35,7X,F16.8)')'LOCALLINKDthr',DALTON%LOCALLINKDthr
WRITE(LUPRI,'(2X,A35,7X,L1)')'FMM',DALTON%FMM
WRITE(LUPRI,'(2X,A35,7X,L1)')'LINK',DALTON%LINK

WRITE(LUPRI,'(2X,A35,7X,L1)')'LSDASCREEN',DALTON%LSDASCREEN
WRITE(LUPRI,'(2X,A35,7X,L1)')'LSDAJENGINE',DALTON%LSDAJENGINE
WRITE(LUPRI,'(2X,A35,7X,L1)')'LSDACOULOMB',DALTON%LSDACOULOMB
WRITE(LUPRI,'(2X,A35,7X,L1)')'LSDALINK',DALTON%LSDALINK
WRITE(LUPRI,'(2X,A35,7X,I8)')'LSDASCREEN_THRLOG',DALTON%LSDASCREEN_THRLOG
WRITE(LUPRI,'(2X,A35,7X,L1)')'DAJENGINE',DALTON%DAJENGINE
WRITE(LUPRI,'(2X,A35,7X,L1)')'DACOULOMB',DALTON%DACOULOMB
WRITE(LUPRI,'(2X,A35,7X,L1)')'DALINK',DALTON%DALINK
WRITE(LUPRI,'(2X,A35,7X,I8)')'DASCREEN_THRLOG',DALTON%DASCREEN_THRLOG
WRITE(LUPRI,'(2X,A35,I8)')'INTPRINT',DALTON%INTPRINT
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGOVERLAP',DALTON%DEBUGOVERLAP
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUG4CENTER',DALTON%DEBUG4CENTER
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGPROP',DALTON%DEBUGPROP
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGEN1INT',DALTON%DEBUGGEN1INT
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGCGTODIFF',DALTON%DEBUGCGTODIFF
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGEP',DALTON%DEBUGEP
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGscreen',DALTON%DEBUGscreen
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGEODERIVOVERLAP',DALTON%DEBUGGEODERIVOVERLAP
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGEODERIVKINETIC',DALTON%DEBUGGEODERIVKINETIC
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGEODERIVEXCHANGE',DALTON%DEBUGGEODERIVEXCHANGE
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGEODERIVCOULOMB',DALTON%DEBUGGEODERIVCOULOMB
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGMAGDERIV',DALTON%DEBUGMAGDERIV
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGMAGDERIVOVERLAP',DALTON%DEBUGMAGDERIVOVERLAP
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUG4CENTER_ERI',DALTON%DEBUG4CENTER_ERI
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGCCFRAGMENT',DALTON%DEBUGCCFRAGMENT
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGKINETIC',DALTON%DEBUGKINETIC
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGNUCPOT',DALTON%DEBUGNUCPOT
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGGGEM', DALTON%DEBUGGGEM
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGLSlib', DALTON%DEBUGLSlib
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGUncontAObatch', DALTON%DEBUGUncontAObatch
WRITE(LUPRI,'(2X,A35,7X,L1)')'DEBUGDECPACKED', DALTON%DEBUGDECPACKED
WRITE(LUPRI,'(2X,A35,7X,L1)')'PARI_J',DALTON%PARI_J
WRITE(LUPRI,'(2X,A35,7X,L1)')'PARI_K',DALTON%PARI_K
WRITE(LUPRI,'(2X,A35,7X,L1)')'SIMPLE_PARI',DALTON%SIMPLE_PARI
WRITE(LUPRI,'(2X,A35,7X,L1)')'NON_ROBUST_PARI',DALTON%NON_ROBUST_PARI
WRITE(LUPRI,'(2X,A35,7X,L1)')'PARI_CHARGE',DALTON%PARI_CHARGE
WRITE(LUPRI,'(2X,A35,7X,L1)')'PARI_DIPOLE',DALTON%PARI_DIPOLE
WRITE(LUPRI,'(2X,A35,7X,L1)')'DO4CENTERERI',DALTON%DO4CENTERERI
WRITE(LUPRI,'(2X,A35,7X,L1)')'OVERLAP_DF_J',DALTON%OVERLAP_DF_J
WRITE(LUPRI,'(2X,A35,7X,L1)')'TIMINGS',DALTON%TIMINGS
WRITE(LUPRI,'(2X,A35,7X,L1)')'nonSphericalETUV',DALTON%nonSphericalETUV

WRITE(LUPRI,'(2X,A35,I8)')'BASPRINT',DALTON%BASPRINT
WRITE(LUPRI,'(2X,A35,7X,L1)')'ATOMBASIS',DALTON%ATOMBASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'BASIS',DALTON%BASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'AUXBASIS',DALTON%AUXBASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'NOFAMILY',DALTON%NOFAMILY
WRITE(LUPRI,'(2X,A35,7X,L1)')'Hermiteecoeff',DALTON%Hermiteecoeff
WRITE(LUPRI,'(2X,A35,7X,L1)')'DoSpherical',DALTON%DoSpherical
WRITE(LUPRI,'(2X,A35,7X,L1)')'UNCONT',DALTON%UNCONT
WRITE(LUPRI,'(2X,A35,7X,L1)')'NOSEGMENT',DALTON%NOSEGMENT

WRITE(LUPRI,'(2X,A35,7X,L1)')'DO3CENTEROVL',DALTON%DO3CENTEROVL
WRITE(LUPRI,'(2X,A35,7X,L1)')'DO2CENTERERI',DALTON%DO2CENTERERI
WRITE(LUPRI,'(2X,A35,I8)')'CARMOM',DALTON%CARMOM
WRITE(LUPRI,'(2X,A35,7X,L1)')'MIXEDOVERLAP',DALTON%MIXEDOVERLAP

!*CAUCHY-SCHWARZ INTEGRAL PARAMETERS
WRITE(LUPRI,'(2X,A35,F16.8)')'CS_THRESHOLD',DALTON%CS_THRESHOLD
WRITE(LUPRI,'(2X,A35,F16.8)')'PARI_THRESHOLD',DALTON%PARI_THRESHOLD
WRITE(LUPRI,'(2X,A35,F16.8)')'J_THR',DALTON%J_THR
WRITE(LUPRI,'(2X,A35,F16.8)')'K_THR',DALTON%K_THR
WRITE(LUPRI,'(2X,A35,F16.8)')'ONEEL_THR',DALTON%ONEEL_THR
WRITE(LUPRI,'(2X,A35,7X,L1)')'CS_SCREEN',DALTON%CS_SCREEN
WRITE(LUPRI,'(2X,A35,7X,L1)')'PARI_SCREEN',DALTON%PARI_SCREEN
WRITE(LUPRI,'(2X,A35,7X,L1)')'saveGABtoMem',DALTON%saveGABtoMem
!*PRIMITIVE INTEGRAL PARAMETERS
WRITE(LUPRI,'(2X,A35,F16.8)')'PS_THRESHOLD',DALTON%PS_THRESHOLD
WRITE(LUPRI,'(2X,A35,7X,L1)')'PS_SCREEN',DALTON%PS_SCREEN
WRITE(LUPRI,'(2X,A35,7X,L1)')'PS_DEBUG',DALTON%PS_DEBUG
WRITE(LUPRI,'(2X,A35,7X,L1)')'FRAGMENT',DALTON%FRAGMENT
WRITE(LUPRI,'(2X,A35,7X,I16)')'numAtomsPerFragment',DALTON%numAtomsPerFragment

!Coulomb attenuated method CAM parameters
WRITE(LUPRI,'(2X,A35,7X,L1)')'LR_EXCHANGE_DF',DALTON%LR_EXCHANGE_DF
WRITE(LUPRI,'(2X,A35,7X,L1)')'LR_EXCHANGE_PARI',DALTON%LR_EXCHANGE_PARI
WRITE(LUPRI,'(2X,A35,7X,L1)')'LR_EXCHANGE',DALTON%LR_EXCHANGE
WRITE(LUPRI,'(2X,A35,7X,L1)')'ADMM_EXCHANGE',DALTON%ADMM_EXCHANGE
WRITE(LUPRI,'(2X,A35,7X,L1)')'ADMM_GCBASIS',DALTON%ADMM_GCBASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'ADMM_JKBASIS',DALTON%ADMM_JKBASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'ADMM_DFBASIS',DALTON%ADMM_DFBASIS
WRITE(LUPRI,'(2X,A35,7X,L1)')'ADMM_MCWEENY',DALTON%ADMM_MCWEENY
WRITE(LUPRI,'(2X,A35,7X,L1)')'SR_EXCHANGE',DALTON%SR_EXCHANGE
WRITE(LUPRI,'(2X,A35,7X,L1)')'CAM',DALTON%CAM
WRITE(LUPRI,'(2X,A35,F16.8)') 'CAMalpha',DALTON%CAMalpha
WRITE(LUPRI,'(2X,A35,F16.8)') 'CAMbeta',DALTON%CAMbeta
WRITE(LUPRI,'(2X,A35,F16.8)') 'CAMmu',DALTON%CAMmu

!DFT PARAMETERS
call WRITE_FORMATTET_DFT_param(LUPRI,DALTON%DFT)
!EXCHANGE FACTOR
WRITE(LUPRI,'(2X,A35,F16.8)') 'exchangeFactor',DALTON%exchangeFactor

END SUBROUTINE PRINT_DALTONITEM

!> \brief print the IO item structure
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param IO the ioitem to be printet
!> \param lupri the logical unit number to write to
SUBROUTINE PRINT_IOITEM(IO,LUPRI)
implicit none
TYPE(IOITEM)  :: IO
INTEGER       :: LUPRI
!
INTEGER :: I

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE IOITEM'
WRITE(LUPRI,*)' '
WRITE(LUPRI,'(2X,A35,7X,I4)')'numfiles',IO%numFiles
DO I=1,IO%numFiles
   WRITE(LUPRI,'(A8,A72)')'FILENAME',IO%filename(I)(1:72)
   WRITE(LUPRI,'(A8,I10)')'IUNIT   ',IO%IUNIT(I)
   WRITE(LUPRI,'(A8,L1)') 'isopen  ',IO%isopen(I)
ENDDO

END SUBROUTINE PRINT_IOITEM

!> \brief print the molceule and basis info
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param molecule the molecule structure
!> \param basinfo the basis info structure
SUBROUTINE PRINT_MOLECULE_AND_BASIS(LUPRI,MOLECULE,basInfo)
IMPLICIT NONE
TYPE(BASISSETINFO),intent(in) :: basInfo
TYPE(MOLECULEINFO),intent(in) :: MOLECULE
INTEGER,intent(in)            :: LUPRI
!
INTEGER             :: I,TOTCHARGE,TOTprim,TOTcont,icharge,R,set,type
CHARACTER(len=45)   :: CC 
LOGICAl             :: printbas,printed_dots
INTEGER             :: oldset,oldtype,K,J,atom_of_type,L
WRITE(LUPRI,*) '                     '

WRITE(LUPRI,'(A)')'Atoms and basis sets'
WRITE (LUPRI,'(A,I7)') '  Total number of atoms        :',MOLECULE%natoms
TOTCHARGE=0
TOTprim=0
TOTcont=0
R=basInfo%labelindex
WRITE(LUPRI,'(2X,A3,2X,A9,A10,I4)')'THE',basInfo%label,' is on R =',R
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
        &-------------'
WRITE (LUPRI,'(2X,A4,1X,A5,2X,A6,1X,A8,16X,A4,5X,A4,3X,A5)')'atom','label','charge'&
     &,'basisset','prim','cont','basis'
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
                                                                &-------------'
oldset=0
oldtype=0
atom_of_type = 0
printed_dots=.FALSE.
PRINTBAS = .TRUE.
DO I=1,MOLECULE%nAtoms
   IF(basInfo%labelindex .EQ. 0)THEN
      ICHARGE = INT(MOLECULE%ATOM(I)%charge) 
      type= basInfo%Chargeindex(ICHARGE)
   ELSE
      type=MOLECULE%ATOM(I)%IDtype(R)
   ENDIF
   IF(oldtype .EQ. type)THEN !OLDTYPE
      atom_of_type = atom_of_type+1
      IF(atom_of_type.GT. 10)THEN
         PRINTBAS = .FALSE.
         IF(.NOT.printed_dots)THEN
            WRITE (LUPRI,'(A7,1X,A4,1X,A7,1X,A20,1X,A7,2X,A7,1X,A25)') &
                 & '      :',':   ' ,'    :  ','    :               ',&
                 & '      :','      :','       :                 '
            printed_dots=.TRUE.
         ENDIF
      ENDIF
   ELSE
      atom_of_type = 0 
      printed_dots=.FALSE.
   ENDIF

   IF(.NOT.MOLECULE%ATOM(I)%phantom)THEN
      TOTCHARGE=TOTCHARGE+NINT(MOLECULE%ATOM(I)%Charge)
   ENDIF
   IF(.NOT.MOLECULE%ATOM(I)%pointcharge)THEN
      TOTprim=TOTprim+basInfo%ATOMTYPE(type)%Totnprim
      TOTcont=TOTcont+basInfo%ATOMTYPE(type)%Totnorb
   ENDIF
   IF(PRINTBAS)THEN
      IF(MOLECULE%ATOM(I)%pointcharge)THEN
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,2X,I7,1X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & MOLECULE%ATOM(I)%Charge,&
              & 'pointcharge         ',0,0, ' '
      ELSEIF(MOLECULE%ATOM(I)%phantom)THEN
         CALL BASTYP(LUPRI,MOLECULE,basInfo,I,type,CC)         
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,2X,I7,1X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & 0.0E0_realk,&
              & basInfo%ATOMTYPE(type)%Name,&
              & basInfo%ATOMTYPE(type)%Totnprim,&
              & basInfo%ATOMTYPE(type)%Totnorb, CC
      ELSE
         CALL BASTYP(LUPRI,MOLECULE,basInfo,I,type,CC)         
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,2X,I7,1X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & MOLECULE%ATOM(I)%Charge,&
              & basInfo%ATOMTYPE(type)%Name,&
              & basInfo%ATOMTYPE(type)%Totnprim,&
              & basInfo%ATOMTYPE(type)%Totnorb, CC
      ENDIF
   ENDIF
   oldtype = type
   PRINTBAS = .TRUE.
ENDDO

WRITE (LUPRI,'(A)')'--------------------------------------------------------&
     &-------------'
WRITE (LUPRI,'(A9,I7,26X,I7,2X,I7)')'total         ',TOTCHARGE,TOTprim,TOTcont
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
     &-------------'
WRITE(LUPRI,*) '                     '
END SUBROUTINE PRINT_MOLECULE_AND_BASIS

!> \brief print the molceule and basis info
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param molecule the molecule structure
!> \param basinfo the basis info structure
SUBROUTINE PRINT_LEVEL2BASIS(LUPRI,MOLECULE,basInfo)
IMPLICIT NONE
TYPE(BASISSETINFO),intent(in) :: basInfo
TYPE(MOLECULEINFO),intent(in) :: MOLECULE
INTEGER,intent(in)            :: LUPRI
!
INTEGER             :: I,TOTCHARGE,TOTprim,TOTcont,icharge,R,set,type
CHARACTER(len=45)   :: CC 
LOGICAl             :: printbas,printed_dots
INTEGER             :: oldset,oldtype,K,J,atom_of_type,L
WRITE (LUPRI,'(A,I7)') '  Total number of atoms        :',MOLECULE%natoms
TOTCHARGE=0
TOTprim=0
TOTcont=0
R=basInfo%labelindex
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
        &-------------'
WRITE (LUPRI,'(2X,A4,1X,A5,2X,A6,1X,A8,16X,A4,3X,A5)')'atom','label','charge'&
     &,'basisset','cont','basis'
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
                                                                &-------------'
oldset=0
oldtype=0
atom_of_type = 0
printed_dots=.FALSE.
PRINTBAS = .TRUE.
DO I=1,MOLECULE%nAtoms
   IF(basInfo%labelindex .EQ. 0)THEN
      ICHARGE = INT(MOLECULE%ATOM(I)%charge) 
      type= basInfo%Chargeindex(ICHARGE)
   ELSE
      type=MOLECULE%ATOM(I)%IDtype(R)
   ENDIF
   IF(oldtype .EQ. type)THEN !OLDTYPE
      atom_of_type = atom_of_type+1
      IF(atom_of_type.GT. 10)THEN
         PRINTBAS = .FALSE.
         IF(.NOT.printed_dots)THEN
            WRITE (LUPRI,'(A7,1X,A4,1X,A7,1X,A20,1X,A7,3X,A25)') &
                 & '      :',':   ' ,'    :  ','    :               ',&
                 & '      :','      :','       :                 '
            printed_dots=.TRUE.
         ENDIF
      ENDIF
   ELSE
      atom_of_type = 0 
      printed_dots=.FALSE.
   ENDIF

   IF(.NOT.MOLECULE%ATOM(I)%phantom)THEN
      TOTCHARGE=TOTCHARGE+basInfo%ATOMTYPE(type)%Charge
   ENDIF
   IF(.NOT.MOLECULE%ATOM(I)%pointcharge)THEN
      TOTprim=TOTprim+basInfo%ATOMTYPE(type)%Totnprim
      TOTcont=TOTcont+basInfo%ATOMTYPE(type)%Totnorb
   ENDIF
   IF(PRINTBAS)THEN
      IF(MOLECULE%ATOM(I)%pointcharge)THEN
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,3X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & MOLECULE%ATOM(I)%Charge,&
              & 'pointcharge         ',&
              & 0, CC
      ELSEIF(MOLECULE%ATOM(I)%phantom)THEN
         CALL BASTYP2(LUPRI,MOLECULE,basInfo,I,type,CC)         
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,3X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & 0.0E0_realk,&
              & 'GC Minimal Basis    ',&
              & basInfo%ATOMTYPE(type)%Totnorb, CC
      ELSE
         CALL BASTYP2(LUPRI,MOLECULE,basInfo,I,type,CC)         
         WRITE (LUPRI,'(I7,1X,A4,1X,F7.3,1X,A20,1X,I7,3X,A45)') &
              & I,MOLECULE%ATOM(I)%NAME,&
              & MOLECULE%ATOM(I)%Charge,&
              & 'GC Minimal Basis    ',&
              & basInfo%ATOMTYPE(type)%Totnorb, CC
      ENDIF
   ENDIF
   oldtype = type
   PRINTBAS = .TRUE.
ENDDO

WRITE (LUPRI,'(A)')'--------------------------------------------------------&
     &-------------'
WRITE (LUPRI,'(A9,I7,26X,I7)')'total         ',TOTCHARGE,TOTcont
WRITE (LUPRI,'(A)')'--------------------------------------------------------&
     &-------------'
WRITE(LUPRI,*) '                     '
END SUBROUTINE PRINT_LEVEL2BASIS

!> \brief determine the label CC used in print molecule and basis
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param molecule the molecule structure
!> \param basisinfo the basis info structure
!> \param I not used
!> \param type the atomtype in the BASISINFO structure 
!> \param CC the label used in print molecule and basis
SUBROUTINE BASTYP(LUPRI,MOLECULE,BASISINFO,I,type,CC)
implicit none
TYPE(BASISSETINFO)  :: BASISINFO
TYPE(MOLECULEINFO)  :: MOLECULE
CHARACTER(len=45)   :: CC 
CHARACTER(len=1)    :: CC1
CHARACTER(len=1)    :: spdfgh(10)=(/'s','p','d','f','g','h','i','j','k','l'/) 
CHARACTER(len=2)    :: CC2 
INTEGER             :: I,J,L,IND,K,type,set,LUPRI

CC='                                             '
CC(1:1) = '['
IND=2
DO J=1,BASISINFO%ATOMTYPE(type)%nANGMOM
  L=BASISINFO%ATOMTYPE(type)%SHELL(J)%nprim
  IF(L .LT. 100 .AND. L .GT. 0)THEN
    IF(L<10)THEN
      CC1=Char(L+48)
      CC(IND:IND)=CC1
      IND=IND+1
    ELSE
      CC2=Char(L/10+48)//Char(mod(L,10)+48)
      CC(IND:IND+1)=CC2
      IND=IND+2
    ENDIF
  ELSE
!    IF(L .NE. 0) PRINT*,'ERROR DO YOU REALLY HAVE MORE THAN 99 primitives?'
  ENDIF
  IF(L .NE. 0) THEN
     IF (J.GT. 10) CALL LSQUIT('Need to modify BASTYP for nANGMOM.GT. 10',-1)
     CC(IND:IND)=spdfgh(J)
     IND=IND+1
  ENDIF
ENDDO

CC(IND:IND) = '|'
IND = IND + 1

DO J=1,BASISINFO%ATOMTYPE(type)%nANGMOM
  L=BASISINFO%ATOMTYPE(type)%SHELL(J)%norb
  IF(L .LT. 100 .AND. L .GT. 0)THEN
    IF(L<10)THEN
      CC1=Char(L+48)
      CC(IND:IND)=CC1
      IND=IND+1
    ELSE
      CC2=Char(L/10+48)//Char(mod(L,10)+48)
      CC(IND:IND+1)=CC2
      IND=IND+2
    ENDIF
  ELSE
!    IF(L .NE. 0) PRINT*,'ERROR DO YOU REALLY HAVE MORE THAN 99 primitives?'
  ENDIF
  IF(L .NE. 0) THEN
     CC(IND:IND)=spdfgh(J)
     IND=IND+1
  ENDIF
ENDDO

CC(IND:IND) = ']'

END SUBROUTINE BASTYP

!> \brief determine the label CC used in print molecule and basis
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param molecule the molecule structure
!> \param basisinfo the basis info structure
!> \param I not used
!> \param type the atomtype in the BASISINFO structure 
!> \param CC the label used in print molecule and basis
SUBROUTINE BASTYP2(LUPRI,MOLECULE,BASISINFO,I,type,CC)
implicit none
TYPE(BASISSETINFO)  :: BASISINFO
TYPE(MOLECULEINFO)  :: MOLECULE
CHARACTER(len=45)   :: CC 
CHARACTER(len=1)    :: CC1
CHARACTER(len=1)    :: spdfgh(10)=(/'s','p','d','f','g','h','i','j','k','l'/) 
CHARACTER(len=2)    :: CC2 
INTEGER             :: I,J,L,IND,K,type,set,LUPRI

CC='                                             '
CC(1:1) = '['
IND=2
DO J=1,BASISINFO%ATOMTYPE(type)%nANGMOM
  L=BASISINFO%ATOMTYPE(type)%SHELL(J)%norb
  IF(L .LT. 100 .AND. L .GT. 0)THEN
    IF(L<10)THEN
      CC1=Char(L+48)
      CC(IND:IND)=CC1
      IND=IND+1
    ELSE
      CC2=Char(L/10+48)//Char(mod(L,10)+48)
      CC(IND:IND+1)=CC2
      IND=IND+2
    ENDIF
  ELSE
!    IF(L .NE. 0) PRINT*,'ERROR DO YOU REALLY HAVE MORE THAN 99 primitives?'
  ENDIF
  IF(L .NE. 0) THEN
     CC(IND:IND)=spdfgh(J)
     IND=IND+1
  ENDIF
ENDDO

CC(IND:IND) = ']'

END SUBROUTINE BASTYP2

subroutine PrintFragmentInfoAndBlocks(SETTING,LUPRI)
implicit none
TYPE(LSSETTING) :: SETTING
INTEGER :: LUPRI
!
INTEGER :: I
#ifdef VAR_LSMPI
write(lupri,*)'PrintFragmentInfoAndBlocks: infpar%mynum=',infpar%mynum
#endif
DO I=1,SETTING%nAO
   WRITE(LUPRI,*)'AO NUMBER',I
   WRITE(LUPRI,*)'FRAGMENT AND BASIS'
   CALL PRINT_MOLECULEINFO(LUPRI,SETTING%FRAGMENT(I)%p,SETTING%BASIS(I)%p,0)
   CALL PRINT_MOLECULE_AND_BASIS(LUPRI,SETTING%FRAGMENT(I)%p,SETTING%BASIS(I)%p%REGULAR)   
ENDDO

CALL PRINT_FRAGMENTITEM(SETTING%FRAGMENTS,LUPRI)

end subroutine PrintFragmentInfoAndBlocks

subroutine print_fragmentitem(fragitem,LUPRI)
implicit none
type(fragmentitem) :: fragitem
INTEGER :: LUPRI
!
INTEGER :: I,J

WRITE(LUPRI,*)'The FragmentItem'
DO I = 1,4
   WRITE(LUPRI,'(A,I2,A,I4)')'numFragments(',I,')  =',fragitem%numFragments(I)
   WRITE(LUPRI,'(A,I2,A,L1)')'numFragments(',I,')  =',fragitem%infoAllocated(I)
   WRITE(LUPRI,'(A,I2,A,4L1)')'identical(1:4,',I,') =',(fragitem%identical(J,I),J=1,4)
   CALL PRINT_FRAGMENTINFO(LUPRI,FRAGITEM%INFO(I)%p,1)
   WRITE(LUPRI,'(A,I4)')'iLHS =',FRAGITEM%iLHSblock
   CALL PRINT_BLOCKINFO(LUPRI,FRAGITEM%LHSblock,'LHS')
   WRITE(LUPRI,'(A,I4)')'iRHS =',FRAGITEM%iRHSblock
   CALL PRINT_BLOCKINFO(LUPRI,FRAGITEM%RHSblock,'RHS')
ENDDO

end subroutine print_fragmentitem

!> \brief print the fragmentinfo
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param fragment the fragmentinfo to be printet
!> \param Label 
SUBROUTINE PRINT_FRAGMENTINFO(LUPRI,FRAGMENT,LABEL)
implicit none
TYPE(FRAGMENTINFO) :: FRAGMENT
INTEGER            :: I,LABEL
INTEGER            :: LUPRI
CHARACTER(len=7)   :: STRING(5)
WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE FRAGMENTINFO'
WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(2X,A,2X,I3)') 'Number of fragments    = ',FRAGMENT%numFragments
WRITE(LUPRI,'(2X,A,2X,L1)') 'Number of Orbital Sets = ',FRAGMENT%numberOrbialsSet

WRITE(LUPRI,*) '--------------------------------------------------------------------------'
WRITE(LUPRI,'(2X,A,2X,A,2X,A,2X,A,2X,A,2X,A,2X,A)')'Fragment','Basis','nPrimOrb',&
     &'nContOrb','nStartContOrb','nStartPrimOrb','Atoms'
WRITE(LUPRI,*) '--------------------------------------------------------------------------'
STRING(1) = 'Regular'
STRING(2) = 'DF-Aux '
STRING(3) = 'CABS   '
STRING(4) = 'JKAux  '
STRING(5) = 'Valence'
DO I=1,FRAGMENT%numFragments
   WRITE(LUPRI,'(2X,I3,6X,A7,6X,I3,7X,I3,12X,I3,12X,I3,4X,I3)') I, STRING(LABEL), &
        & FRAGMENT%nPrimOrb(I,LABEL),& 
        & FRAGMENT%nContOrb(I,LABEL), FRAGMENT%nStartContOrb(I,LABEL), &
        & FRAGMENT%nStartPrimOrb(I,LABEL), FRAGMENT%nATOMS(I)
ENDDO
END SUBROUTINE PRINT_FRAGMENTINFO

!> \brief print the blockinfo
!> \author S. Reine and T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number to write to
!> \param blocks the blockinfo to be printet
!> \param Label 
SUBROUTINE PRINT_BLOCKINFO(LUPRI,BLOCKS,LABEL)
implicit none
TYPE(BLOCKINFO) :: BLOCKS
INTEGER         :: I
CHARACTER LABEL*(*)
INTEGER         :: LUPRI

WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(A)')'THE '//LABEL//'BLOCKINFO'
WRITE(LUPRI,*) '                     '
WRITE(LUPRI,'(1X,A,I3)') 'Number of blocks    = ',BLOCKS%numBlocks

   WRITE(LUPRI,*) '--------------------------------------------------------------------'
   WRITE(LUPRI,'(1X,A5,1X,A5,1X,A6,1X,A6,1X,A6,1X,A6,1X,A6,1X,A6,1X,A4)')&
        &'Frag1','Frag2','nbast1','nbast2','nAtoms1','nAtoms2',&
        &'start1','start2','node'
   WRITE(LUPRI,*) '--------------------------------------------------------------------'

DO I=1,BLOCKS%numBlocks
   WRITE(LUPRI,'(1X,I5,1X,I5,1X,I6,1X,I6,1X,I6,1X,I6,2X,I6,2X,I6,1X,I4)') &
        & BLOCKS%blocks(I)%fragment1,&
        & BLOCKS%blocks(I)%fragment2, BLOCKS%blocks(I)%nbast1,& 
        & BLOCKS%blocks(I)%nbast2, BLOCKS%blocks(I)%nAtoms1, &
        & BLOCKS%blocks(I)%nAtoms2, BLOCKS%blocks(I)%startOrb1,& 
        & BLOCKS%blocks(I)%startOrb2, BLOCKS%blocks(I)%node
ENDDO

WRITE(LUPRI,*) '                     '

END SUBROUTINE PRINT_BLOCKINFO

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it puts information into the real and integer buffer
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_FILLBUFFER(OUTPUT,JE,M,IB,IA,J1,J2,IBTCH,IND,EXT,OD1,OD2,OD3,SPHINT,ATOMA,ATOMB,ISCOOR)
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   INTEGER      :: M, IB, IA, J1,J2,IBTCH,IND,JE
   INTEGER      :: I, ATOMA, ATOMB, ISCOOR
   REAL(REALK)  :: EXT,OD1,OD2,OD3,SPHINT
   I = OUTPUT%IBUFI
   OUTPUT%IBUF(1,I)=JE 
   OUTPUT%IBUF(2,I)=M
   OUTPUT%IBUF(3,I)=iB
   OUTPUT%IBUF(4,I)=iA
   OUTPUT%IBUF(5,I)=J1
   OUTPUT%IBUF(6,I)=J2
   OUTPUT%IBUF(7,I)=IBTCH
   OUTPUT%IBUF(8,I)=IND
   OUTPUT%IBUF(9 ,I)=ATOMA
   OUTPUT%IBUF(10,I)=ATOMB
   OUTPUT%IBUF(11,I)=ISCOOR
! the real buffer
   OUTPUT%RBUF(1,I)=EXT
   OUTPUT%RBUF(2,I)=OD1
   OUTPUT%RBUF(3,I)=OD2
   OUTPUT%RBUF(4,I)=OD3
   OUTPUT%RBUF(5,I)=SPHINT

   OUTPUT%IBUFI= OUTPUT%IBUFI+ 1
END SUBROUTINE LS_FILLBUFFER

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it empties the integer buffer
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_EMPTYIBUF(OUTPUT,IBUFFER,LUINTM)
! ATTENTION: counter is not reset !
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   INTEGER     :: IBUFFER((OUTPUT%IBUFI-1)*OUTPUT%MAXBUFI)
   INTEGER     :: LUINTM, II, I
   II = OUTPUT%MAXBUFI*(OUTPUT%IBUFI-1)
   WRITE(LUINTM) II
   WRITE(LUINTM) (IBUFFER(I),I=1,II)
END SUBROUTINE LS_EMPTYIBUF

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it empties the real buffer
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_EMPTYRBUF(OUTPUT,RBUFFER,LUINTR)
! ATTENTION: counter is reset
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   REAL(REALK) :: RBUFFER((OUTPUT%IBUFI-1)*OUTPUT%MAXBUFR)
   INTEGER     :: LUINTR, II, I
   II = OUTPUT%MAXBUFR*(OUTPUT%IBUFI-1)
   WRITE(LUINTR) II
   WRITE(LUINTR) (RBUFFER(I),I=1,II)
   OUTPUT%IBUFI = 1
END SUBROUTINE LS_EMPTYRBUF

!SUBROUTINE LS_EMPTYBUF(OUTPUT,IBUFFER,RBUFFER,LUINTM,LUINTMR)
! this subroutine is needed in the multipole moment calculation when using a buffer for writing
! it empties the integer and the real buffer
!   IMPLICIT NONE
!   TYPE(INTEGRALOUTPUT) :: OUTPUT
!   INTEGER     :: IBUFFER(OUTPUT%MAXBUFI*(OUTPUT%IBUFI-1))
!!   INTEGER     :: LUINTM, LUINTMR, IBUFI, IBUFR, I
!   REAL(REALK) :: RBUFFER(OUTPUT%MAXBUFR*(OUTPUT%IBUFI-1))
!   IBUFI = OUTPUT%MAXBUFI*(OUTPUT%IBUFI-1)
!   IBUFR = OUTPUT%MAXBUFR*(OUTPUT%IBUFI-1)
!   WRITE(LUINTM) IBUFI
!   WRITE(LUINTM) (IBUFFER(I),I=1,IBUFI)
!   WRITE(LUINTMR) IBUFR
!   WRITE(LUINTMR) (RBUFFER(I),I=1,IBUFR)
!END SUBROUTINE LS_EMPTYBUF

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it puts nuclear information into the buffer
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_FILLNUCBUF(OUTPUT,CHARGE,X,Y,Z)
   IMPLICIT NONE 
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   REAL(REALK)          :: CHARGE, X,Y,Z
   INTEGER              :: I
   I = OUTPUT%IBUFN
   OUTPUT%NBUF(1,I) = CHARGE
   OUTPUT%NBUF(2,I) = X
   OUTPUT%NBUF(3,I) = Y
   OUTPUT%NBUF(4,I) = Z
   OUTPUT%IBUFN = OUTPUT%IBUFN+1
END SUBROUTINE LS_FILLNUCBUF

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it empties the nuclear position buffer
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_EMPTYNUCBUF(OUTPUT,RBUFFER,LUINTMR)
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   REAL(REALK) :: RBUFFER((OUTPUT%IBUFN-1)*OUTPUT%MAXBUFN)
   INTEGER :: LUINTMR, II,I
   II = (OUTPUT%IBUFN-1)*OUTPUT%MAXBUFN
   WRITE(LUINTMR) II
   WRITE(LUINTMR) (RBUFFER(I),I=1,II)   
   OUTPUT%IBUFN = 1
END SUBROUTINE LS_EMPTYNUCBUF

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it initializes the buffer arrays
!> \author S. Reine
!> \date 2010
!>
!> and ATTENTION: passes the MMBUFLEN, MAXBUFN, MAXBUFR, MAXBUFI parameters 
!>                to the COMMON block variables in cbifmm.h
!>                which are needed in the fmm routines
!>
SUBROUTINE LS_INITMMBUF(OUTPUT,NDER)
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   INTEGER :: NDER
   OUTPUT%MMBUFLEN  = 2000
   OUTPUT%IBUFI  = 1
   OUTPUT%IBUFN  = 1
   OUTPUT%MAXBUFN = 4
   IF (NDER .EQ. 1 .OR. NDER .EQ. 2)  THEN
      OUTPUT%MAXBUFR = 5
      OUTPUT%MAXBUFI = 11
   ELSE
      CALL LSQUIT('UNDEFINED BUFFERLENGTH FOR MM-BUFFER FOR HIGHER DERIVATIVES?',-1)
   ENDIF

   call mem_alloc(OUTPUT%IBUF,OUTPUT%MAXBUFI,OUTPUT%MMBUFLEN)
   call mem_alloc(OUTPUT%RBUF,OUTPUT%MAXBUFR,OUTPUT%MMBUFLEN)
   call mem_alloc(OUTPUT%NBUF,OUTPUT%MAXBUFN,OUTPUT%MMBUFLEN)
   CALL INITBUFMEM(OUTPUT%IBUF,OUTPUT%RBUF,OUTPUT%NBUF,OUTPUT%MAXBUFI,OUTPUT%MAXBUFR,OUTPUT%MAXBUFN,OUTPUT%MMBUFLEN)

   CALL SETMMBUFINFO(OUTPUT%USEBUFMM,OUTPUT%MMBUFLEN,OUTPUT%MAXBUFI,OUTPUT%MAXBUFR,OUTPUT%MAXBUFN)

END SUBROUTINE LS_INITMMBUF

!> \brief this subroutine is needed in the multipole moment calculation when using a buffer for writing it empties the nuclear position buffe
!> \author S. Reine
!> \date 2010
SUBROUTINE LS_FREEMMBUF(OUTPUT)
   IMPLICIT NONE
   TYPE(INTEGRALOUTPUT) :: OUTPUT
   call mem_dealloc(OUTPUT%IBUF)
   call mem_dealloc(OUTPUT%RBUF)
   call mem_dealloc(OUTPUT%NBUF)
END SUBROUTINE LS_FREEMMBUF

!> \brief 
!> \author S. Reine
!> \date 2010
SUBROUTINE INITBUFMEM(IBUFFER,RBUFFER,NBUFFER,MAXI,MAXR,MAXN,MAXL)
   IMPLICIT NONE
   INTEGER :: I,MAXI,MAXR,MAXN,MAXL
   INTEGER :: IBUFFER(MAXI*MAXL)
   REAL(REALK) :: RBUFFER(MAXR*MAXL), NBUFFER(MAXN*MAXL)
   DO I=1, MAXR*MAXL
      RBUFFER(I) = 0.0E0_realk
   ENDDO
   DO I=1, MAXI*MAXL
      IBUFFER(I) = 0
   ENDDO
   DO I=1, MAXN*MAXL
      NBUFFER(I) = 0.0E0_realk
   ENDDO
END SUBROUTINE INITBUFMEM

!> \brief Slave routine to build scalapack matrix from memdist lstensor format
!> \author T. Kjaergaard
!> \date 2012
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
SUBROUTINE retrieve_output_slave(lupri,setting)
implicit none
TYPE(LSSETTING) :: setting
integer,intent(in) :: lupri
call memdist_lstensor_BuildToScalapack(setting%Output%resultTensor,&
     & setting%comm,setting%node,setting%numnodes)
END SUBROUTINE retrieve_output_slave

!> \brief retrieve the output from the setting and put it into a single matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param singleMAT the output matrix 
SUBROUTINE retrieve_output_mat_single(lupri,setting,singleMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
TYPE(MATRIX)    :: singleMAT 
integer,intent(in) :: lupri
logical,intent(in) :: IntegralTransformGC
!
TYPE(MATRIX)    :: TMP
!
IF(setting%Output%memdistResultTensor)then
   call memdist_lstensor_BuildToScalapack(setting%Output%resultTensor,&
        & setting%comm,setting%node,setting%numnodes,singleMAT)
ELSE
    call Build_mat_from_lst(lupri,setting%Output%resultTensor,singleMAT)
ENDIF
call retrieve_postprocess(setting%Output%postprocess(1),singleMAT,lupri)
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
if(IntegralTransformGC)THEN
   call AO2GCAO_transform_matrixF(singleMAT,setting,lupri)
ENDIF
call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_mat_single

subroutine retrieve_postprocess(postprocess,MAT,lupri)
integer :: postprocess,lupri
type(matrix) :: MAT
!
type(matrix) :: TMP

IF(postprocess.NE.0)THEN
   select case(postprocess)
   CASE(SymFromTriangularPostprocess)
      !lstensor_full_symMat_from_triangularMat
      call mat_setlowertriangular_zero(MAT)
      call mat_init(TMP,MAT%ncol,MAT%nrow)
      call mat_trans(MAT,TMP)
      call mat_daxpy(1.E0_realk,TMP,MAT)
      call mat_scal_dia(0.5E0_realk,MAT)
      call mat_free(TMP)
   CASE(SymmetricPostprocess)
      !Symmetrize
      call util_get_symm_part(MAT)
   CASE(AntiSymmetricPostprocess)
      !AntiSymmetrize
      call mat_init(TMP,MAT%ncol,MAT%nrow)
      call util_get_antisymm_part(MAT,TMP)
      call mat_assign(MAT,TMP)
      call mat_free(TMP)      
   CASE DEFAULT
      CALL LSQUIT('unkown type in retrieve_postprocess',-1)
   END SELECT
endif
end subroutine retrieve_postprocess


!> \brief retrieve the output from the setting and put it into a single lstensor
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param tensor the output lstensor
SUBROUTINE retrieve_output_lstensor(lupri,setting,tensor,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
TYPE(lstensor)    :: tensor
integer,intent(in)   :: lupri
logical,intent(in) :: IntegralTransformGC

if(IntegralTransformGC)call lsquit('retrieve_output_lstensor not implemented for IntegralTransformGC',lupri)
call copy_lstensor_to_lstensor(setting%Output%resultTensor,tensor)
IF(setting%Output%postprocess(1).NE.0)then
   call lsquit('retrieve_postprocess error in retrieve_output_lstensor',-1)
endif
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_lstensor

!> \brief retrieve maxGabelm from the setting and put it into integer(short)
!> \author J. Rekkedal
!> \date 2012
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param tensor the output lstensor
SUBROUTINE retrieve_output_maxGabelm(lupri,setting,maxGAB,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
TYPE(lstensor)    :: tensor
integer,intent(in)   :: lupri
logical,intent(in) :: IntegralTransformGC
INTEGER(kind=short),intent(out)        :: maxGAB

if(IntegralTransformGC) then
  write(lupri,*) 'In retrieve_output_int_short'
  write(*,*) 'In retrieve_output_int_short'
  call lsquit('IntegralTransformGC not implemented yet',lupri) 
else
  maxGab=setting%Output%resulttensor%maxgabelm
endif
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
call mem_dealloc(setting%Output%postprocess)

END SUBROUTINE retrieve_output_maxGabelm

!> \brief retrieve the screen output from the setting
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param tensor the output lstensor
SUBROUTINE retrieve_screen_output(lupri,setting,tensor,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
TYPE(lstensor)    :: tensor
integer,intent(in)   :: lupri
logical,intent(in) :: IntegralTransformGC

IF(setting%Output%postprocess(1).NE.0)then
   call lsquit('retrieve_postprocess error in retrieve_screen_output',-1)
endif
if(IntegralTransformGC)call lsquit('retrieve_output_lstensor not implemented for IntegralTransformGC',lupri)
call copy_lstensor_to_lstensor(setting%Output%screenTensor,tensor)
call lstensor_free(setting%Output%screenTensor)
deallocate(setting%Output%screenTensor)
nullify(setting%Output%screenTensor)
call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_screen_output

!> \brief retrieve the output from the setting and put it into an array matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param arrayMAT the output matrix 
SUBROUTINE retrieve_output_mat_array(lupri,setting,arrayMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
TYPE(MATRIX)    :: arrayMAT(:)
integer,intent(in)   :: lupri
logical,intent(in) :: IntegralTransformGC
!
TYPE(MATRIX)    :: TMP
integer :: I
IF(setting%Output%memdistResultTensor)then
   IF(size(arrayMAT).GT.1)call lsquit('ndmat .gt. 1 in retrieve_output_mat_array scalapack',-1)
   call memdist_lstensor_BuildToScalapack(setting%Output%resultTensor,&
        & setting%comm,setting%node,setting%numnodes,arrayMAT(1))
ELSE
   call Build_mat_from_lst(lupri,setting%Output%resultTensor,arrayMAT)
ENDIF
do I=1,size(arrayMAT)
   call retrieve_postprocess(setting%Output%postprocess(I),arrayMAT(I),lupri)
enddo
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
if(IntegralTransformGC)THEN
   do I=1,size(arrayMAT)
      call AO2GCAO_transform_matrixF(arrayMAT(I),setting,lupri)
   enddo
ENDIF

call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_mat_array

!> \brief retrieve the output from the setting and put it into an 5 dim array
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param fullmat the output 5 dim array
SUBROUTINE retrieve_output_5dim(lupri,setting,fullMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
REAL(REALK)      :: fullMAT(:,:,:,:,:)
integer   :: lupri,ndim1,ndim2,ndim3,ndim4,ndim5
logical,intent(in) :: IntegralTransformGC

IF(setting%Output%postprocess(1).NE.0)then
   call lsquit('retrieve_postprocess error in retrieve_output',-1)
endif
if(IntegralTransformGC)call lsquit('retrieve_output_5dim not implemented for IntegralTransformGC',lupri)
ndim1 = setting%Output%resultTensor%nbast(1)
ndim2 = setting%Output%resultTensor%nbast(2)
ndim3 = setting%Output%resultTensor%nbast(3)
ndim4 = setting%Output%resultTensor%nbast(4)
ndim5 = setting%Output%resultTensor%ndim5
Call Build_full_5dim_from_lstensor(setting%Output%resultTensor,&
     &fullMAT,ndim1,ndim2,ndim3,ndim4,ndim5)
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)

call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_5dim

!> \brief retrieve the output from the setting and put it into an 4 dim array
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param fullmat the output 5 dim array
SUBROUTINE retrieve_output_4dim(lupri,setting,fullMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
REAL(REALK)      :: fullMAT(:,:,:,:)
integer   :: lupri,ndim1,ndim2,ndim3,ndim4,ndim5
logical,intent(in) :: IntegralTransformGC

IF(setting%Output%postprocess(1).NE.0)then
   call lsquit('retrieve_postprocess error in retrieve_output',-1)
endif
if(IntegralTransformGC)call lsquit('retrieve_output_5dim not implemented for IntegralTransformGC',lupri)
ndim1 = setting%Output%resultTensor%nbast(1)
ndim2 = setting%Output%resultTensor%nbast(2)
ndim3 = setting%Output%resultTensor%nbast(3)
ndim4 = setting%Output%resultTensor%nbast(4)
ndim5 = setting%Output%resultTensor%ndim5
IF(ndim5.NE. 1)call lsquit('Error in retrieve_output_5dim',lupri)

Call Build_full_4dim_from_lstensor(setting%Output%resultTensor,&
     &fullMAT,ndim1,ndim2,ndim3,ndim4)
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_4dim

!call retrieve_postprocess_full(setting%Output%postprocess(1),singleMAT,lupri)
subroutine retrieve_postprocess_full(postprocess,MAT,ndim,lupri)
integer :: postprocess,lupri,ndim
real(realk) :: MAT(ndim,ndim)
!
real(realk),pointer :: TMP(:,:)

IF(postprocess.NE.0)THEN
   select case(postprocess)
   CASE(SymFromTriangularPostprocess)
      !lstensor_full_symMat_from_triangularMat
      call set_lowertriangular_zero(MAT,ndim,ndim)
      call mem_alloc(TMP,ndim,ndim)
      call ls_transpose(MAT,TMP,ndim)
      call daxpy(ndim*ndim,1.E0_realk,TMP,1,MAT,1)
      call mem_dealloc(TMP)
      call dscal(ndim,0.5E0_realk,MAT,ndim+1)
   CASE(SymmetricPostprocess)
      !Symmetrize
      call mem_alloc(TMP,ndim,ndim)
      call ls_transpose(MAT,TMP,ndim)
      call dscal(ndim*ndim,0.5E0_realk,MAT,1)
      call daxpy(ndim*ndim,0.5E0_realk,TMP,1,MAT,1)
      call mem_dealloc(TMP)
   CASE(AntiSymmetricPostprocess)
      !Symmetrize
      call mem_alloc(TMP,ndim,ndim)
      call ls_transpose(MAT,TMP,ndim)
      call dscal(ndim*ndim,0.5E0_realk,MAT,1)
      call daxpy(ndim*ndim,-0.5E0_realk,TMP,1,MAT,1)
      call mem_dealloc(TMP)
   CASE DEFAULT
      CALL LSQUIT('unkown type in retrieve_postprocess',-1)
   END SELECT
endif
end subroutine retrieve_postprocess_full

!> \brief retrieve the output from the setting and put it into an 3 dim array
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param fullmat the output 3 dim array
SUBROUTINE retrieve_output_3dim(lupri,setting,fullMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
REAL(REALK)      :: fullMAT(:,:,:)
integer   :: lupri,ndim1,ndim2,ndim3,ndim4,ndim5,n1,n2,n3,I
REAL(REALK),pointer      :: fullMATtmp(:,:,:,:,:)
logical,intent(in) :: IntegralTransformGC

if(IntegralTransformGC)call lsquit('retrieve_output_3dim not implemented for IntegralTransformGC',lupri)
ndim1 = setting%Output%resultTensor%nbast(1)
ndim2 = setting%Output%resultTensor%nbast(2)
ndim3 = setting%Output%resultTensor%nbast(3)
ndim4 = setting%Output%resultTensor%nbast(4)
ndim5 = setting%Output%resultTensor%ndim5
n1 = size(fullMAT,1)
n2 = size(fullMAT,2)
n3 = size(fullMAT,3)
IF (ndim1*ndim2*ndim3*ndim4*ndim5.NE.n1*n2*n3) THEN
  WRITE(LUPRI,'(1X,A)') 'Error in retrieve_output_3dim. Mismatching dimensions'
  CALL LSQUIT('Error in retrieve_output_3dim. Mismatching dimensions',-1)
ENDIF
call mem_alloc(fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
Call Build_full_5dim_from_lstensor(setting%Output%resultTensor,&
     &fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
call lstensor_free(setting%Output%resultTensor)
deallocate(setting%Output%resultTensor)
nullify(setting%Output%resultTensor)
call dcopy(ndim1*ndim2*ndim3*ndim4*ndim5,fullMATtmp,1,fullMAT,1)
call mem_dealloc(fullMATtmp)
IF(setting%Output%postprocess(1).NE.0)then
   IF(n1.NE.n2)call lsquit('option not tested n1.NE.n2 retrieve_output_3dim',-1)
   DO I=1,n3
      call retrieve_postprocess_full(setting%Output%postprocess(1),&
           & fullMAT(:,:,I),n1,lupri)
   ENDDO
endif
call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_3dim

!> \brief retrieve the output from the setting and put it into an 2 dim array
!> \author T. Kjaergaard
!> \date 2010
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param fullmat the output 2 dim array
SUBROUTINE retrieve_output_2dim(lupri,setting,fullMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
REAL(REALK)     :: fullMAT(:,:)
integer         :: lupri
!
integer             :: I,J,ndim1,ndim2,ndim3,ndim4,ndim5,n1,n2
integer             :: natom1,natom2,natom3,natom4
Real(realk),pointer :: fullMATtmp(:,:,:,:,:)
logical,intent(in) :: IntegralTransformGC
IF(setting%output%resultTensor%gradienttensor)THEN
   natom1=setting%output%resultTensor%natom(1)
   natom2=setting%output%resultTensor%natom(2)
   natom3=setting%output%resultTensor%natom(3)
   natom4=setting%output%resultTensor%natom(4)
   call build_grad_from_gradlstensor(setting%output%resultTensor,fullmat,&
        & natom1+natom2+natom3+natom4,setting%output%resultTensor%ndim5,lupri)
   call lstensor_free(setting%Output%resultTensor)
   deallocate(setting%Output%resultTensor)
   nullify(setting%Output%resultTensor)
ELSE
  ndim1 = setting%Output%resultTensor%nbast(1)
  ndim2 = setting%Output%resultTensor%nbast(2)
  ndim3 = setting%Output%resultTensor%nbast(3)
  ndim4 = setting%Output%resultTensor%nbast(4)
  ndim5 = setting%Output%resultTensor%ndim5
  n1 = size(fullMAT,1)
  n2 = size(fullMAT,2)
  IF (ndim1*ndim2*ndim3*ndim4*ndim5.NE.n1*n2) THEN
    WRITE(LUPRI,'(1X,A)') 'Error in retrieve_output_2dim. Mismatching dimensions'

    WRITE(LUPRI,'(1X,A)') 'n1',n1
    WRITE(LUPRI,'(1X,A)') 'n2',n2
    WRITE(LUPRI,'(1X,A)') 'ndim1',ndim1
    WRITE(LUPRI,'(1X,A)') 'ndim2',ndim2
    WRITE(LUPRI,'(1X,A)') 'ndim3',ndim3
    WRITE(LUPRI,'(1X,A)') 'ndim4',ndim4
    WRITE(LUPRI,'(1X,A)') 'ndim5',ndim5
    CALL LSQUIT('Error in retrieve_output_2dim. Mismatching dimensions',-1)
  ENDIF
  call mem_alloc(fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
  Call Build_full_5dim_from_lstensor(setting%Output%resultTensor,&
       &fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
  call lstensor_free(setting%Output%resultTensor)
  deallocate(setting%Output%resultTensor)
  nullify(setting%Output%resultTensor)
  call dcopy(ndim1*ndim2*ndim3*ndim4*ndim5,fullMATtmp,1,fullMAT,1)
  call mem_dealloc(fullMATtmp)
  if(IntegralTransformGC)THEN
     if(n1.NE.n2)call lsquit('AO2GCAO_transform_full only works for square matrices',lupri)
      call AO2GCAO_transform_fullF(fullMAT,n1,setting,lupri)
   endif
   IF(setting%Output%postprocess(1).NE.0)then
      IF(n1.NE.n2)call lsquit('option not tested n1.NE.n2 retrieve_output_3dim',-1)
      call retrieve_postprocess_full(setting%Output%postprocess(1),&
           & fullMAT,n1,lupri)
   endif
ENDIF

!IF(setting%output%resultTensor%gradienttensor)THEN
!   call build_grad_from_gradlstensor(setting%output%resultTensor,fullmat,&
!        &setting%output%resultTensor%natom1,setting%output%resultTensor%nmat,lupri)
!   call lstensor_free(setting%Output%resultTensor)
!ELSE
!   call Build_full_2dim_from_lstensor(setting%Output%resultTensor,&
!        &fullMAT,setting%Output%ndim(1),setting%Output%ndim(2))
!   call lstensor_free(setting%Output%resultTensor)
!ENDIF
!if(setting%IntegralTransformGC)

call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_2dim

!> \brief retrieve the output from the setting and put it into an 1 dim array
!> \author S. Reine
!> \date 2011-01-27
!> \param lupri the logical unit number for the output
!> \param setting contains the output in lstensor format 
!> \param fullmat the output 1 dim array
SUBROUTINE retrieve_output_1dim(lupri,setting,fullMAT,IntegralTransformGC)
implicit none
TYPE(LSSETTING) :: setting
REAL(REALK)     :: fullMAT(:)
integer         :: lupri
!
integer             :: I,J,ndim1,ndim2,ndim3,ndim4,ndim5,n1
Real(realk),pointer :: fullMATtmp(:,:,:,:,:)
logical,intent(in) :: IntegralTransformGC

IF(setting%Output%postprocess(1).NE.0)then
   call lsquit('retrieve_postprocess error in retrieve_output',-1)
endif
ndim1 = setting%Output%resultTensor%nbast(1)
ndim2 = setting%Output%resultTensor%nbast(2)
ndim3 = setting%Output%resultTensor%nbast(3)
ndim4 = setting%Output%resultTensor%nbast(4)
ndim5 = setting%Output%resultTensor%ndim5
n1 = size(fullMAT(:))
IF (setting%Output%resultTensor%pChargeTensor)THEN
   IF(setting%Output%resultTensor%nAtom(1)*ndim5.NE.n1) THEN
      WRITE(LUPRI,'(1X,A)') 'Error in retrieve_output_1dim.A. Mismatching dimensions'
      CALL LSQUIT('Error in retrieve_output_1dim.A. Mismatching dimensions',-1)
   ENDIF
   ndim1=setting%Output%resultTensor%nAtom(1)
   ndim2=1; ndim3=1; ndim4=1
   call mem_alloc(fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
   Call Build_full_5dim_from_lstensor(setting%Output%resultTensor,&
        &fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
   call lstensor_free(setting%Output%resultTensor)
   deallocate(setting%Output%resultTensor)
   nullify(setting%Output%resultTensor)
   call dcopy(ndim1*ndim2*ndim3*ndim4*ndim5,fullMATtmp,1,fullMAT,1)
   call mem_dealloc(fullMATtmp)
ELSE
   IF(setting%Output%ResultTensor%ndim5.EQ.n1)THEN
!      DO I=1,n1
!         fullMAT(I) = setting%Output%ResultTensor%LSAO(1)%BATCH(1,1,1,1)%elms(I)
!      ENDDO
      call dcopy(n1,setting%Output%ResultTensor%LSAO(1)%elms,1,fullMAT,1)
      call lstensor_free(setting%Output%resultTensor)
!      deallocate(setting%Output%resultTensor)
!      nullify(setting%Output%resultTensor)
   ELSEIF(ndim1*ndim2*ndim3*ndim4*ndim5.EQ.n1) THEN
      call mem_alloc(fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
      Call Build_full_5dim_from_lstensor(setting%Output%resultTensor,&
           &fullMATtmp,ndim1,ndim2,ndim3,ndim4,ndim5)
      call lstensor_free(setting%Output%resultTensor)
      deallocate(setting%Output%resultTensor)
      nullify(setting%Output%resultTensor)
      call dcopy(ndim1*ndim2*ndim3*ndim4*ndim5,fullMATtmp,1,fullMAT,1)
      call mem_dealloc(fullMATtmp)
   ELSE
      WRITE(LUPRI,'(1X,A)') 'Error in retrieve_output_1dim.B. Mismatching dimensions'
      CALL LSQUIT('Error in retrieve_output_1dim.B. Mismatching dimensions',-1)
   ENDIF
ENDIF

call mem_dealloc(setting%Output%postprocess)
END SUBROUTINE retrieve_output_1dim

!> \brief copy the lssetting structure
!> \author T. Kjaergaard
!> \date 2010
!> \param newsetting the new setting structure
!> \param oldsetting the original setting structure
!> \param lupri the logical unit number for the output
SUBROUTINE copy_setting(newsetting,oldsetting,lupri)
implicit none
type(lssetting),intent(in)    :: oldsetting
type(lssetting),intent(inout) :: newsetting
integer :: lupri
!
integer :: I,nAO,ndmat,dim1,dim2,dim3

call typedef_init_setting(newSETTING)

newsetting%comm = oldsetting%comm
newsetting%IntegralTransformGC = oldsetting%IntegralTransformGC
newsetting%DO_DFT = oldsetting%DO_DFT
newsetting%Edisp = oldsetting%Edisp
newsetting%nAO = oldsetting%nAO
newsetting%SCHEME = oldsetting%SCHEME

nAO = newsetting%nAO
do I = 1,nAO
   nullify(newsetting%Molecule(I)%p)
   allocate(newsetting%Molecule(I)%p)
   call copy_molecule(oldsetting%Molecule(I)%p,newsetting%Molecule(I)%p,lupri)
   nullify(newsetting%Fragment(I)%p)
!   allocate(newsetting%Fragment(I)%p)
!   call copy_molecule(oldsetting%Fragment(I)%p,newsetting%Fragment(I)%p,lupri)
   nullify(newsetting%Basis(I)%p)
   allocate(newsetting%Basis(I)%p)
   newsetting%Basis(I)%p%GCtransAlloc = oldsetting%basis(I)%p%GCtransAlloc
   IF(oldsetting%basis(I)%p%GCtransAlloc)THEN
      call copy_basissetinfo(oldsetting%basis(I)%p%GCtrans,newsetting%basis(I)%p%GCtrans) 
   ELSE
      newsetting%basis(I)%p%GCtrans%nAtomtypes=0
      newsetting%basis(I)%p%GCtrans%labelindex=0
      newsetting%basis(I)%p%GCtrans%nChargeindex=0
      nullify(newsetting%basis(I)%p%GCtrans%ATOMTYPE)
   ENDIF
   call copy_basissetinfo(oldsetting%basis(I)%p%REGULAR,newsetting%basis(I)%p%REGULAR) 
   call copy_basissetinfo(oldsetting%basis(I)%p%AUXILIARY,newsetting%basis(I)%p%AUXILIARY) 
   call copy_basissetinfo(oldsetting%basis(I)%p%CABS,newsetting%basis(I)%p%CABS) 
   call copy_basissetinfo(oldsetting%basis(I)%p%JK,newsetting%basis(I)%p%JK) 
   call copy_basissetinfo(oldsetting%basis(I)%p%VALENCE,newsetting%basis(I)%p%VALENCE) 
   newsetting%Batchindex(I) = oldsetting%Batchindex(I)
   newsetting%Batchsize(I) = oldsetting%Batchsize(I)
   newsetting%Batchdim(I) = oldsetting%Batchdim(I)
   newsetting%molID(I) = oldsetting%molID(I) 
enddo

newsetting%molBuild = .TRUE.
newsetting%basBuild = .TRUE.
newsetting%fragBuild = .FALSE.

newsetting%sameMOL = oldSETTING%sameMOL
newsetting%sameBAS = oldSETTING%sameBAS
newsetting%sameFRAG = oldSETTING%sameFRAG
newSETTING%nDmatLHS = oldSETTING%nDmatLHS
newSETTING%nDmatRHS = oldSETTING%nDmatRHS
IF (oldSetting%lstensor_attached) THEN
   CALL LSQUIT('Error in copy_setting. lstensor_attached = TRUE',-1)
ELSE
  newSETTING%lstensor_attached = .FALSE.   !LSSETTING029
  NULLIFY(newSETTING%lst_dLHS)             !LSSETTING021
  NULLIFY(newSETTING%lst_dRHS)             !LSSETTING022
ENDIF

newSETTING%LHSdmat = oldSETTING%LHSdmat
newSETTING%RHSdmat = oldSETTING%RHSdmat

newSETTING%LHSdfull = oldSETTING%LHSdfull
newSETTING%RHSdfull = oldSETTING%RHSdfull

NULLIFY(newSETTING%DsymLHS)
NULLIFY(newSETTING%DsymRHS)
 
IF(newSETTING%LHSdmat)THEN
   call lsquit('copy setting errror1',lupri)
ENDIF
IF(newSETTING%RHSdmat)THEN
   call lsquit('copy setting errror2',lupri)
ENDIF
IF(newSETTING%LHSdfull)THEN
   call lsquit('copy setting errror3',lupri)
ENDIF
newSETTING%LHSdalloc = .FALSE.
newSETTING%RHSdalloc = .FALSE.
newSETTING%LHSdmatAlloc = .FALSE.
newSETTING%RHSdmatAlloc = .FALSE.


IF(newSETTING%RHSdfull)THEN
   call lsquit('copy setting errror4',lupri)
ENDIF 

newSETTING%LHSdmatAOindex1 = oldSETTING%LHSdmatAOindex1 
newSETTING%LHSdmatAOindex2 = oldSETTING%LHSdmatAOindex2 
newSETTING%RHSdmatAOindex1 = oldSETTING%RHSdmatAOindex1
newSETTING%RHSdmatAOindex2 = oldSETTING%RHSdmatAOindex2
newSETTING%numFragments = oldSETTING%numFragments
newSETTING%numNodes = oldSETTING%numNodes
newSETTING%node  = oldSETTING%node 
newsetting%SCHEME = oldsetting%SCHEME

call COPY_IOITEM(oldsetting%IO,newsetting%IO)
!IO have been allocated in init_setting!
!call COPY_AND_ALLOC_SCREENITEM(newsetting%SCREEN,oldsetting%SCREEN)

IF(associated(oldSETTING%LST_GAB_LHS))CALL LSQUIT('copy_setting err1',-1)
IF(associated(oldSETTING%LST_GAB_RHS))CALL LSQUIT('copy_setting err2',-1)
NULLIFY(newSETTING%LST_GAB_LHS)
NULLIFY(newSETTING%LST_GAB_RHS)

call copy_reduced_screening_info(newsetting%RedCS,oldsetting%RedCS)
END SUBROUTINE copy_setting

SUBROUTINE SET_SAMEALLFRAG(sameAllFrag,sameFrag,nAO)
implicit none
logical,intent(inout) :: sameAllFrag
integer,intent(in)    :: nAO
logical,intent(in)    :: samefrag(nAO,nAO)
!
integer JAO,IAO

sameAllFrag = .TRUE.
DO JAO = 1,nAO
   DO IAO = 1,nAO
      IF(.NOT.sameFrag(IAO,JAO))THEN
         sameAllFrag = .FALSE.
         EXIT
      ENDIF
   ENDDO
ENDDO

END SUBROUTINE SET_SAMEALLFRAG

SUBROUTINE typedef_setMolecules_2_1(setting,mol1,ao1,ao2,mol2,ao3)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1,mol2
Integer, intent(in)                  :: ao1,ao2,ao3
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1
setting%molecule(ao2)%p => mol1
setting%molecule(ao3)%p => mol2

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO
setting%sameMol(ao1,ao2) = .true.
setting%sameMol(ao2,ao1) = .true.

END SUBROUTINE typedef_setMolecules_2_1

SUBROUTINE typedef_setMolecules_2(setting,mol1,ao1,ao2)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1
Integer, intent(in)                  :: ao1,ao2
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1
setting%molecule(ao2)%p => mol1

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO
setting%sameMol(ao1,ao2) = .true.
setting%sameMol(ao2,ao1) = .true.

END SUBROUTINE typedef_setMolecules_2

SUBROUTINE typedef_setMolecules_1(setting,mol1,ao1)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1
Integer, intent(in)                  :: ao1
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO

END SUBROUTINE typedef_setMolecules_1

SUBROUTINE typedef_setMolecules_1_1(setting,mol1,ao1,mol2,ao2)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1,mol2
Integer, intent(in)                  :: ao1,ao2
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1
setting%molecule(ao2)%p => mol2

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO

END SUBROUTINE typedef_setMolecules_1_1

SUBROUTINE typedef_setMolecules_1_1_1(setting,mol1,ao1,mol2,ao2,mol3,ao3)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1,mol2,mol3
Integer, intent(in)                  :: ao1,ao2,ao3
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1
setting%molecule(ao2)%p => mol2
setting%molecule(ao3)%p => mol3

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO

END SUBROUTINE typedef_setMolecules_1_1_1

SUBROUTINE typedef_setMolecules_1_1_1_1(setting,mol1,ao1,mol2,ao2,mol3,ao3,mol4,ao4)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol1,mol2,mol3,mol4
Integer, intent(in)                  :: ao1,ao2,ao3,ao4
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol1
setting%molecule(ao2)%p => mol2
setting%molecule(ao3)%p => mol3
setting%molecule(ao4)%p => mol4

setting%sameMol = .false.
DO iao=1,4
  setting%sameMol(iao,iao) = .true.
ENDDO

END SUBROUTINE typedef_setMolecules_1_1_1_1

SUBROUTINE typedef_setMolecules_4(setting,mol,ao1,ao2,ao3,ao4)
implicit none
TYPE(LSSETTING),intent(inout)        :: setting
TYPE(MOLECULEINFO),intent(in),target :: mol
Integer, intent(in)                  :: ao1,ao2,ao3,ao4
!
Integer :: iao

DO iao=1,4
  NULLIFY(setting%molecule(iao)%p)
ENDDO

setting%molecule(ao1)%p => mol
setting%molecule(ao2)%p => mol
setting%molecule(ao3)%p => mol
setting%molecule(ao4)%p => mol

setting%sameMol = .true.

END SUBROUTINE typedef_setMolecules_4

!> \brief set default values for the lssetting structure
!> \author T. Kjaergaard
!> \date 2010
!> \param setting the setting structure
!> \param input the daltoninput structure
SUBROUTINE typedef_set_default_setting(SETTING,INPUT)
implicit none
TYPE(LSSETTING)   :: SETTING
TYPE(DALTONINPUT) :: INPUT
!
Integer :: iAO
#ifdef VAR_LSMPI
SETTING%comm = MPI_COMM_LSDALTON
#else
SETTING%comm = 0
#endif

SETTING%IntegralTransformGC = .FALSE.
SETTING%DO_DFT = INPUT%DO_DFT
DO iAO=1,SETTING%nAO
  SETTING%MOLECULE(iAO)%p => INPUT%MOLECULE
  SETTING%BASIS(iAO)%p    => INPUT%BASIS
  SETTING%FRAGMENT(iAO)%p => INPUT%MOLECULE
  SETTING%BATCHINDEX(iAO)= 0
  SETTING%BATCHSIZE(iAO)= 1
  SETTING%BATCHDIM(iAO)= 0
  SETTING%molID(iAO)= 0
ENDDO
SETTING%sameMOL  = .TRUE.
SETTING%sameBAS  = .TRUE.
SETTING%sameFRAG = .TRUE.

!Simen ToDo Should be removed from input
SETTING%node = INPUT%node
SETTING%numNodes = INPUT%numNodes
SETTING%numFragments = INPUT%numFragments
CALL typedef_setIntegralSchemeFromInput(INPUT%DALTON,SETTING%SCHEME)
SETTING%LHSSameAsRHSDmat  = .FALSE.

SETTING%SCHEME%OD_MOM = .FALSE.
SETTING%SCHEME%MOM_CENTER = (/0E0_realk,0E0_realk,0E0_realk/)
CALL init_reduced_screen_info(SETTING%RedCS)

END SUBROUTINE typedef_set_default_setting

!> \brief initialise the lssetting structure
!> \author T. Kjaergaard
!> \date 2010
!> \param setting the setting structure
SUBROUTINE typedef_init_setting(SETTING)
implicit none
TYPE(LSSETTING)  :: SETTING
INTEGER          :: nAO

nAO = 4
SETTING%nAO = nAO

NULLIFY(SETTING%MOLECULE)
NULLIFY(SETTING%BASIS)
NULLIFY(SETTING%FRAGMENT)
ALLOCATE(SETTING%MOLECULE(nAO))
ALLOCATE(SETTING%BASIS(nAO))
ALLOCATE(SETTING%FRAGMENT(nAO))
call mem_alloc(SETTING%BATCHINDEX,nAO)
call mem_alloc(SETTING%BATCHSIZE,nAO)
call mem_alloc(SETTING%BATCHDIM,nAO)
call mem_alloc(SETTING%molID,nAO)
call mem_alloc(SETTING%molBuild,nAO)
call mem_alloc(SETTING%basBuild,nAO)
call mem_alloc(SETTING%fragBuild,nAO)


SETTING%molBuild = .FALSE.
SETTING%basBuild = .FALSE.
SETTING%fragBuild = .FALSE.
call mem_alloc(SETTING%sameMOL,nAO,nAO)
call mem_alloc(SETTING%sameBAS,nAO,nAO)
call mem_alloc(SETTING%sameFRAG,nAO,nAO)


NULLIFY(SETTING%DmatLHS)
NULLIFY(SETTING%DmatRHS)
SETTING%nDmatLHS = 1
SETTING%nDmatRHS = 1
SETTING%lstensor_attached = .FALSE.   !LSSETTING029
NULLIFY(SETTING%lst_dLHS)             !LSSETTING021
NULLIFY(SETTING%lst_dRHS)             !LSSETTING022
SETTING%LHSdmat = .FALSE.
SETTING%RHSdmat = .FALSE.
SETTING%LHSdmatAlloc = .FALSE.
SETTING%RHSdmatAlloc = .FALSE.
SETTING%LHSdfull = .FALSE.
SETTING%RHSdfull = .FALSE.
SETTING%LHSdalloc = .FALSE.
SETTING%RHSdalloc = .FALSE.

NULLIFY(SETTING%DfullLHS)
NULLIFY(SETTING%DfullRHS)
NULLIFY(SETTING%DsymLHS)
NULLIFY(SETTING%DsymRHS)
CALL io_init(SETTING%IO)
CALL init_GGem(SETTING%GGem)

NULLIFY(SETTING%LST_GAB_LHS)
NULLIFY(SETTING%LST_GAB_RHS)
SETTING%iLST_GAB_LHS = 0
SETTING%iLST_GAB_RHS = 0
SETTING%CS_MAXELM_LHS = 0
SETTING%CS_MAXELM_RHS = 0
SETTING%PS_MAXELM_LHS = 0
SETTING%PS_MAXELM_RHS = 0
SETTING%LHSSameAsRHSDmat  = .FALSE.
call nullifyIntegralOutput(setting%output)

END SUBROUTINE typedef_init_setting

!> \brief free the lssetting structure
!> \author T. Kjaergaard
!> \date 2010
!> \param setting the setting structure
SUBROUTINE typedef_free_setting(SETTING)
!use molecule_module
implicit none
TYPE(LSSETTING)  :: SETTING
INTEGER          :: nAO,iAO,I
nAO = SETTING%nAO

DO iAO=1,nAO
  IF (SETTING%molBuild(iAO))Then
     call free_Moleculeinfo(SETTING%MOLECULE(iAO)%p)
     DEALLOCATE(SETTING%MOLECULE(iAO)%p)
     NULLIFY(SETTING%MOLECULE(iAO)%p)
  ENDIF
  IF (SETTING%basBuild(iAO)) THEN
     IF(SETTING%BASIS(iAO)%p%REGULAR%nAtomtypes.NE.0)THEN
        call free_basissetinfo(SETTING%BASIS(iAO)%p%REGULAR)
     ENDIF
     IF(SETTING%BASIS(iAO)%p%AUXILIARY%nAtomtypes.NE.0)THEN
        call free_basissetinfo(SETTING%BASIS(iAO)%p%AUXILIARY)
     ENDIF
     IF(SETTING%BASIS(iAO)%p%CABS%nAtomtypes.NE.0)THEN
        call free_basissetinfo(SETTING%BASIS(iAO)%p%CABS)
     ENDIF
     IF(SETTING%BASIS(iAO)%p%JK%nAtomtypes.NE.0)THEN
        call free_basissetinfo(SETTING%BASIS(iAO)%p%JK)
     ENDIF
     IF(SETTING%BASIS(iAO)%p%VALENCE%nAtomtypes.NE.0)THEN
        call free_basissetinfo(SETTING%BASIS(iAO)%p%VALENCE)
     ENDIF
     IF(SETTING%BASIS(iAO)%p%GCtransAlloc)THEN
        IF(SETTING%BASIS(iAO)%p%GCtrans%nAtomtypes.NE.0)THEN
           call free_basissetinfo(SETTING%BASIS(iAO)%p%GCtrans)
        ENDIF
     ENDIF
     deallocate(setting%Basis(iAO)%p)
     nullify(setting%Basis(iAO)%p)
  ENDIF
  IF (SETTING%fragBuild(iAO))then
     call free_Moleculeinfo(SETTING%FRAGMENT(iAO)%p)
     DEALLOCATE(SETTING%FRAGMENT(iAO)%p)
     NULLIFY(SETTING%FRAGMENT(iAO)%p)
  endif
ENDDO
DEALLOCATE(SETTING%MOLECULE)
DEALLOCATE(SETTING%BASIS)
DEALLOCATE(SETTING%FRAGMENT)
NULLIFY(SETTING%MOLECULE)
NULLIFY(SETTING%BASIS)
NULLIFY(SETTING%FRAGMENT)

call mem_dealloc(SETTING%BATCHINDEX)
call mem_dealloc(SETTING%BATCHSIZE)
call mem_dealloc(SETTING%BATCHDIM)
call mem_dealloc(SETTING%molID)
call mem_dealloc(SETTING%molBuild)
call mem_dealloc(SETTING%basBuild)
call mem_dealloc(SETTING%fragBuild)
call mem_dealloc(SETTING%sameMOL)
call mem_dealloc(SETTING%sameBAS)
call mem_dealloc(SETTING%sameFRAG)

CALL io_free(SETTING%IO)
CALL free_GGem(SETTING%GGem)

IF (SETTING%lstensor_attached) THEN
  CALL LSQUIT('Error in typedef_free_setting. lstensor_attached = TRUE',-1)
ENDIF

IF(setting%LHSdmatAlloc)THEN
   do I=1,SETTING%nDmatLHS
      IF(setting%scheme%memdist.AND.matrix_type.EQ.mtype_scalapack)THEN      
         !do nothing
      ELSE
         call mat_free(setting%DmatLHS(I)%p)
      ENDIF
      deallocate(setting%DmatLHS(I)%p)
      nullify(setting%DmatLHS(I)%p)
   enddo
   call mem_dealloc(setting%DmatLHS)
ENDIF

IF(setting%RHSdmatAlloc)THEN
   do I=1,SETTING%nDmatRHS
      IF(setting%scheme%memdist.AND.matrix_type.EQ.mtype_scalapack)THEN      
         !do nothing
      ELSE
         call mat_free(setting%DmatRHS(I)%p)
      ENDIF
      deallocate(setting%DmatRHS(I)%p)
      nullify(setting%DmatRHS(I)%p)
   enddo
   call mem_dealloc(setting%DmatRHS)
ENDIF

IF(ASSOCIATED(setting%DsymLHS))THEN
   call mem_dealloc(setting%DsymLHS)
   nullify(setting%DsymLHS)
ENDIF

IF(ASSOCIATED(setting%DsymRHS))THEN
   call mem_dealloc(setting%DsymRHS)
   nullify(setting%DsymRHS)
ENDIF

IF(associated(setting%LST_GAB_LHS))THEN
   DEALLOCATE(SETTING%LST_GAB_LHS)
   NULLIFY(SETTING%LST_GAB_LHS)
#ifdef LSVAR_MPI
! FIXME THIS IS UGLY
   IF(setting%node.NE.infpar%master)then
      call lstensor_free(setting%LST_GAB_LHS) 
   ENDIF
#endif
ENDIF

IF(associated(setting%LST_GAB_RHS))THEN
   DEALLOCATE(SETTING%LST_GAB_RHS)
   NULLIFY(SETTING%LST_GAB_RHS)
#ifdef LSVAR_MPI 
! FIXME THIS IS UGLY
   IF(setting%node.NE.infpar%master)then
      call lstensor_free(setting%LST_GAB_RHS) 
   ENDIF
#endif
ENDIF

IF(SETTING%LHSdfull.AND.SETTING%LHSdalloc)THEN
   call mem_dealloc(SETTING%DfullLHS)
ENDIF

IF(SETTING%RHSdfull.AND.SETTING%RHSdalloc)THEN
   call mem_dealloc(SETTING%DfullRHS)
ENDIF

END SUBROUTINE typedef_free_setting

!> \brief set up the lsint scheme from the integralconfig 
!> \author T. Kjaergaard
!> \date 2010
!> \param dalton_inp the integralconfig structure
!> \param scheme the lsintscheme structure
SUBROUTINE typedef_setIntegralSchemeFromInput(dalton_inp,scheme)
implicit none
TYPE(integralconfig), INTENT(IN) :: dalton_inp
TYPE(LSINTSCHEME),INTENT(INOUT) :: scheme

scheme%noOMP                 = dalton_inp%noOMP
scheme%CFG_LSDALTON          = dalton_inp%CFG_LSDALTON
scheme%DOPASS                = dalton_inp%DOPASS
scheme%DENSFIT               = dalton_inp%DENSFIT
scheme%DF_K                  = dalton_inp%DF_K   
scheme%INTEREST              = dalton_inp%INTEREST
scheme%MATRICESINMEMORY     = dalton_inp%MATRICESINMEMORY
scheme%MEMDIST               = dalton_inp%MEMDIST
scheme%AOPRINT               = dalton_inp%AOPRINT
scheme%INTPRINT              = dalton_inp%INTPRINT
scheme%NOBQBQ                = dalton_inp%NOBQBQ
scheme%JENGINE               = dalton_inp%JENGINE
scheme%FTUVmaxprim           = dalton_inp%FTUVmaxprim
scheme%maxpasses             = dalton_inp%maxpasses
scheme%FMM                   = dalton_inp%FMM
scheme%LINK                  = dalton_inp%LINK
scheme%LSDASCREEN            = dalton_inp%LSDASCREEN
scheme%LSDAJENGINE           = dalton_inp%LSDAJENGINE
scheme%LSDACOULOMB           = dalton_inp%LSDACOULOMB
scheme%LSDALINK              = dalton_inp%LSDALINK
scheme%LSDASCREEN_THRLOG       = dalton_inp%LSDASCREEN_THRLOG
scheme%DAJENGINE             = dalton_inp%DAJENGINE
scheme%DACOULOMB             = dalton_inp%DACOULOMB
scheme%DALINK                = dalton_inp%DALINK
scheme%DASCREEN_THRLOG       = dalton_inp%DASCREEN_THRLOG
scheme%DEBUGOVERLAP          = dalton_inp%DEBUGOVERLAP
scheme%DEBUG4CENTER          = dalton_inp%DEBUG4CENTER
scheme%DEBUG4CENTER_ERI      = dalton_inp%DEBUG4CENTER_ERI
scheme%DEBUGCCFRAGMENT       = dalton_inp%DEBUGCCFRAGMENT
scheme%DEBUGKINETIC          = dalton_inp%DEBUGKINETIC
scheme%DEBUGNUCPOT           = dalton_inp%DEBUGNUCPOT
scheme%PARI_J                = dalton_inp%PARI_J
scheme%PARI_K                = dalton_inp%PARI_K
scheme%SIMPLE_PARI           = dalton_inp%SIMPLE_PARI
scheme%NON_ROBUST_PARI       = dalton_inp%NON_ROBUST_PARI
scheme%PARI_CHARGE           = dalton_inp%PARI_CHARGE
scheme%PARI_DIPOLE           = dalton_inp%PARI_DIPOLE
scheme%DO4CENTERERI          = dalton_inp%DO4CENTERERI
scheme%OVERLAP_DF_J          = dalton_inp%OVERLAP_DF_J
scheme%TIMINGS               = dalton_inp%TIMINGS
scheme%nonSphericalETUV      = dalton_inp%nonSphericalETUV
scheme%HIGH_RJ000_ACCURACY   = dalton_inp%HIGH_RJ000_ACCURACY
scheme%MM_LMAX               = dalton_inp%MM_LMAX
scheme%MM_TLMAX              = dalton_inp%MM_TLMAX
scheme%MM_SCREEN             = dalton_inp%MM_SCREEN
scheme%DO_MMGRD              = dalton_inp%DO_MMGRD
scheme%MM_NOSCREEN           = dalton_inp%MM_NOSCREEN
scheme%NO_MMFILES            = dalton_inp%NO_MMFILES
scheme%MM_NO_ONE             = dalton_inp%MM_NO_ONE
scheme%CREATED_MMFILES       = dalton_inp%CREATED_MMFILES
scheme%USEBUFMM              = dalton_inp%USEBUFMM
scheme%MMunique_ID1          = dalton_inp%MMunique_ID1
scheme%AUXBASIS              = dalton_inp%AUXBASIS
scheme%NOFAMILY              = dalton_inp%NOFAMILY
scheme%Hermiteecoeff         = dalton_inp%Hermiteecoeff
scheme%DoSpherical           = dalton_inp%DoSpherical
scheme%UNCONT                = dalton_inp%UNCONT
scheme%NOSEGMENT             = dalton_inp%NOSEGMENT
scheme%contAng               = dalton_inp%contAng
scheme%DO3CENTEROVL          = dalton_inp%DO3CENTEROVL
scheme%DO2CENTERERI          = dalton_inp%DO2CENTERERI
scheme%CARMOM                = dalton_inp%CARMOM
scheme%SPHMOM                = dalton_inp%SPHMOM
scheme%CMORDER               = 0
scheme%CMiMat                = 0
scheme%MIXEDOVERLAP          = dalton_inp%MIXEDOVERLAP
scheme%ADMM_EXCHANGE         = dalton_inp%ADMM_EXCHANGE
scheme%ADMM_GCBASIS          = dalton_inp%ADMM_GCBASIS 
scheme%ADMM_DFBASIS          = dalton_inp%ADMM_DFBASIS 
scheme%ADMM_JKBASIS          = dalton_inp%ADMM_JKBASIS 
scheme%ADMM_MCWEENY          = dalton_inp%ADMM_MCWEENY 
scheme%THRESHOLD             = dalton_inp%THRESHOLD
scheme%CS_THRESHOLD          = dalton_inp%CS_THRESHOLD
scheme%OE_THRESHOLD          = dalton_inp%OE_THRESHOLD
scheme%PS_THRESHOLD          = dalton_inp%PS_THRESHOLD
scheme%OD_THRESHOLD          = dalton_inp%OD_THRESHOLD
scheme%PARI_THRESHOLD        = dalton_inp%PARI_THRESHOLD
scheme%J_THR                 = dalton_inp%J_THR
scheme%K_THR                 = dalton_inp%K_THR
scheme%ONEEL_THR             = dalton_inp%ONEEL_THR
scheme%IntThreshold          = 1.0E2_realk 
scheme%CS_SCREEN             = dalton_inp%CS_SCREEN
scheme%PARI_SCREEN           = dalton_inp%PARI_SCREEN
scheme%OE_SCREEN             = dalton_inp%OE_SCREEN
scheme%savegabtomem          = dalton_inp%savegabtomem
scheme%ReCalcGab             = .FALSE.
scheme%CS_int                = .FALSE.
scheme%PS_int                = .FALSE.
scheme%PS_SCREEN             = dalton_inp%PS_SCREEN
scheme%PS_DEBUG              = dalton_inp%PS_DEBUG
scheme%OD_SCREEN             = dalton_inp%OD_SCREEN
scheme%MBIE_SCREEN           = dalton_inp%MBIE_SCREEN
scheme%FRAGMENT              = dalton_inp%FRAGMENT
scheme%numAtomsPerFragment   = dalton_inp%numAtomsPerFragment
scheme%LU_LUINTM             = dalton_inp%LU_LUINTM
scheme%LU_LUINTR             = dalton_inp%LU_LUINTR
scheme%LU_LUINDM             = dalton_inp%LU_LUINDM
scheme%LU_LUINDR             = dalton_inp%LU_LUINDR
scheme%LR_EXCHANGE_DF        = dalton_inp%LR_EXCHANGE_DF
scheme%LR_EXCHANGE_PARI      = dalton_inp%LR_EXCHANGE_PARI
scheme%LR_EXCHANGE           = dalton_inp%LR_EXCHANGE
scheme%SR_EXCHANGE           = dalton_inp%SR_EXCHANGE
scheme%CAM                   = dalton_inp%CAM
scheme%CAMalpha              = dalton_inp%CAMalpha
scheme%CAMbeta               = dalton_inp%CAMbeta
scheme%CAMmu                 = dalton_inp%CAMmu
scheme%exchangeFactor        = dalton_inp%exchangeFactor

!DFT parameters 
scheme%DFT  = dalton_inp%DFT

scheme%INCREMENTAL  = .FALSE.
scheme%DO_PROP      = .FALSE.
scheme%PropOper     = -1

END SUBROUTINE typedef_setIntegralSchemeFromInput

!> \brief print the lsint scheme
!> \author T. Kjaergaard
!> \date 2010
!> \param scheme the lsintscheme structure to be printet
!> \param iunit the logical unit number of output 
SUBROUTINE typedef_printScheme(scheme,IUNIT)
implicit none
TYPE(LSINTSCHEME),INTENT(IN) :: scheme
INTEGER,INTENT(IN)           :: IUNIT

WRITE(IUNIT,'(3X,A22,L7)') 'noBQBQ                ', scheme%noBQBQ
WRITE(IUNIT,'(3X,A22,L7)') 'noOMP                 ', scheme%noOMP
WRITE(IUNIT,'(3X,A22,L7)') 'CFG_LSDALTON          ', scheme%CFG_LSDALTON
WRITE(IUNIT,'(3X,A22,L7)') 'DOPASS                ', scheme%DOPASS
WRITE(IUNIT,'(3X,A22,L7)') 'DENSFIT               ', scheme%DENSFIT
WRITE(IUNIT,'(3X,A22,L7)') 'DF_K                  ', scheme%DF_K
WRITE(IUNIT,'(3X,A22,L7)') 'INTEREST              ', scheme%INTEREST
WRITE(IUNIT,'(3X,A22,L7)') 'MATRICESINMEMORY      ', scheme%MATRICESINMEMORY
WRITE(IUNIT,'(3X,A22,L7)') 'MEMDIST               ', scheme%MEMDIST
WRITE(IUNIT,'(3X,A22,I7)') 'AOPRINT               ', scheme%AOPRINT
WRITE(IUNIT,'(3X,A22,I7)') 'INTPRINT              ', scheme%INTPRINT
WRITE(IUNIT,'(3X,A22,L7)') 'JENGINE               ', scheme%JENGINE
WRITE(IUNIT,'(3X,A22,I7)') 'FTUVmaxprim           ', scheme%FTUVmaxprim
WRITE(IUNIT,'(3X,A22,I7)') 'maxpasses             ', scheme%maxpasses
WRITE(IUNIT,'(3X,A22,L7)') 'FMM                   ', scheme%FMM
WRITE(IUNIT,'(3X,A22,L7)') 'LINK                  ', scheme%LINK
WRITE(IUNIT,'(3X,A22,L7)') 'LSDASCREEN            ', scheme%LSDASCREEN
WRITE(IUNIT,'(3X,A22,L7)') 'LSDAJENGINE           ', scheme%LSDAJENGINE
WRITE(IUNIT,'(3X,A22,L7)') 'LSDACOULOMB           ', scheme%LSDACOULOMB
WRITE(IUNIT,'(3X,A22,L7)') 'LSDALINK              ', scheme%LSDALINK
WRITE(IUNIT,'(3X,A22,L7)') 'LSDASCREEN_THRLOG     ', scheme%LSDASCREEN_THRLOG
WRITE(IUNIT,'(3X,A22,L7)') 'DAJENGINE             ', scheme%DAJENGINE
WRITE(IUNIT,'(3X,A22,L7)') 'DACOULOMB             ', scheme%DACOULOMB
WRITE(IUNIT,'(3X,A22,L7)') 'DALINK                ', scheme%DALINK  
WRITE(IUNIT,'(3X,A22,L7)') 'DASCREEN_THRLOG       ', scheme%DASCREEN_THRLOG
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUGOVERLAP          ', scheme%DEBUGOVERLAP
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUG4CENTER          ', scheme%DEBUG4CENTER
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUG4CENTER_ERI      ', scheme%DEBUG4CENTER_ERI
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUGCCFRAGMENT       ', scheme%DEBUGCCFRAGMENT
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUGKINETIC          ', scheme%DEBUGKINETIC
WRITE(IUNIT,'(3X,A22,L7)') 'DEBUGNUCPOT           ', scheme%DEBUGNUCPOT
WRITE(IUNIT,'(3X,A22,L7)') 'DO4CENTERERI          ', scheme%DO4CENTERERI
WRITE(IUNIT,'(3X,A22,L7)') 'OVERLAP_DF_J          ', scheme%OVERLAP_DF_J
WRITE(IUNIT,'(3X,A22,L7)') 'PARI_J                ', scheme%PARI_J          
WRITE(IUNIT,'(3X,A22,L7)') 'PARI_K                ', scheme%PARI_K          
WRITE(IUNIT,'(3X,A22,L7)') 'SIMPLE_PARI           ', scheme%SIMPLE_PARI
WRITE(IUNIT,'(3X,A22,L7)') 'NON_ROBUST_PARI       ', scheme%NON_ROBUST_PARI
WRITE(IUNIT,'(3X,A22,L7)') 'PARI_CHARGE           ', scheme%PARI_CHARGE     
WRITE(IUNIT,'(3X,A22,L7)') 'PARI_DIPOLE           ', scheme%PARI_DIPOLE     
WRITE(IUNIT,'(3X,A22,L7)') 'TIMINGS               ', scheme%TIMINGS
WRITE(IUNIT,'(3X,A22,L7)') 'nonSphericalETUV      ', scheme%nonSphericalETUV
WRITE(IUNIT,'(3X,A22,L7)') 'HIGH_RJ000_ACCURACY   ', scheme%HIGH_RJ000_ACCURACY
WRITE(IUNIT,'(3X,A22,I7)') 'MM_LMAX               ', scheme%MM_LMAX
WRITE(IUNIT,'(3X,A22,I7)') 'MM_TLMAX              ', scheme%MM_TLMAX
WRITE(IUNIT,'(3X,A22,G14.2)') 'MM_SCREEN             ', scheme%MM_SCREEN
WRITE(IUNIT,'(3X,A22,L7)') 'DO_MMGRD              ', scheme%DO_MMGRD
WRITE(IUNIT,'(3X,A22,L7)') 'MM_NOSCREEN           ', scheme%MM_NOSCREEN
WRITE(IUNIT,'(3X,A22,L7)') 'NO_MMFILES            ', scheme%NO_MMFILES            
WRITE(IUNIT,'(3X,A22,L7)') 'MM_NO_ONE             ', scheme%MM_NO_ONE             
WRITE(IUNIT,'(3X,A22,L7)') 'CREATED_MMFILES       ', scheme%CREATED_MMFILES       
WRITE(IUNIT,'(3X,A22,L7)') 'USEBUFMM              ', scheme%USEBUFMM              
WRITE(IUNIT,'(3X,A22,I7)') 'MMunique_ID1          ', scheme%MMunique_ID1          
WRITE(IUNIT,'(3X,A22,L7)') 'AUXBASIS              ', scheme%AUXBASIS              
WRITE(IUNIT,'(3X,A22,L7)') 'NOFAMILY              ', scheme%NOFAMILY              
WRITE(IUNIT,'(3X,A22,L7)') 'Hermiteecoeff           ', scheme%Hermiteecoeff
WRITE(IUNIT,'(3X,A22,L7)') 'DoSpherical           ', scheme%DoSpherical           
WRITE(IUNIT,'(3X,A22,L7)') 'UNCONT                ', scheme%UNCONT                
WRITE(IUNIT,'(3X,A22,L7)') 'NOSEGMENT             ', scheme%NOSEGMENT             
WRITE(IUNIT,'(3X,A22,L7)') 'ContAng               ', scheme%ContAng               
WRITE(IUNIT,'(3X,A22,L7)') 'DO3CENTEROVL          ', scheme%DO3CENTEROVL          
WRITE(IUNIT,'(3X,A22,L7)') 'DO2CENTERERI          ', scheme%DO2CENTERERI          
WRITE(IUNIT,'(3X,A22,I7)') 'CARMOM                ', scheme%CARMOM                
WRITE(IUNIT,'(3X,A22,I7)') 'SPHMOM                ', scheme%SPHMOM             
WRITE(IUNIT,'(3X,A22,L7)') 'CMORDER               ', scheme%CMORDER
WRITE(IUNIT,'(3X,A22,I7)') 'CMIMAT                ', scheme%CMIMAT
WRITE(IUNIT,'(3X,A22,L7)') 'MIXEDOVERLAP          ', scheme%MIXEDOVERLAP
WRITE(IUNIT,'(3X,A22,L7)') 'ADMM_EXCHANGE         ', scheme%ADMM_EXCHANGE
WRITE(IUNIT,'(3X,A22,L7)') 'ADMM_GCBASIS          ', scheme%ADMM_GCBASIS 
WRITE(IUNIT,'(3X,A22,L7)') 'ADMM_DFBASIS          ', scheme%ADMM_DFBASIS 
WRITE(IUNIT,'(3X,A22,L7)') 'ADMM_JKBASIS          ', scheme%ADMM_JKBASIS 
WRITE(IUNIT,'(3X,A22,L7)') 'ADMM_MCWEENY          ', scheme%ADMM_MCWEENY 
WRITE(IUNIT,'(3X,A22,G14.2)') 'THRESHOLD             ', scheme%THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'CS_THRESHOLD          ', scheme%CS_THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'OE_THRESHOLD          ', scheme%OE_THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'PS_THRESHOLD          ', scheme%PS_THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'OD_THRESHOLD          ', scheme%OD_THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'PARI_THRESHOLD        ', scheme%PARI_THRESHOLD
WRITE(IUNIT,'(3X,A22,G14.2)') 'J_THR                 ', scheme%J_THR
WRITE(IUNIT,'(3X,A22,G14.2)') 'K_THR                 ', scheme%K_THR
WRITE(IUNIT,'(3X,A22,G14.2)') 'ONEEL_THR             ', scheme%ONEEL_THR
WRITE(IUNIT,'(3X,A22,G14.2)') 'IntThreshold          ', scheme%IntThreshold     
WRITE(IUNIT,'(3X,A22,L7)') 'CS_SCREEN             ', scheme%CS_SCREEN             
WRITE(IUNIT,'(3X,A22,L7)') 'PARI_SCREEN           ', scheme%PARI_SCREEN
WRITE(IUNIT,'(3X,A22,L7)') 'OE_SCREEN             ', scheme%OE_SCREEN             
WRITE(IUNIT,'(3X,A22,L7)') 'savegabtomem          ', scheme%savegabtomem
WRITE(IUNIT,'(3X,A22,L7)') 'reCalcGab             ', scheme%reCalcGab
WRITE(IUNIT,'(3X,A22,L7)') 'CS_int                ', scheme%CS_int
WRITE(IUNIT,'(3X,A22,L7)') 'PS_int                ', scheme%PS_int
WRITE(IUNIT,'(3X,A22,L7)') 'PS_SCREEN             ', scheme%PS_SCREEN             
WRITE(IUNIT,'(3X,A22,L7)') 'PS_DEBUG              ', scheme%PS_DEBUG              
WRITE(IUNIT,'(3X,A22,L7)') 'OD_SCREEN             ', scheme%OD_SCREEN  
WRITE(IUNIT,'(3X,A22,L7)') 'MBIE_SCREEN           ', scheme%MBIE_SCREEN
WRITE(IUNIT,'(3X,A22,L7)') 'FRAGMENT              ', scheme%FRAGMENT              
WRITE(IUNIT,'(3X,A22,I16)') 'numAtomsPerFragment   ', scheme%numAtomsPerFragment   
WRITE(IUNIT,'(3X,A22,I7)') 'LU_LUINTM             ', scheme%LU_LUINTM             
WRITE(IUNIT,'(3X,A22,I7)') 'LU_LUINTR             ', scheme%LU_LUINTR             
WRITE(IUNIT,'(3X,A22,L7)') 'SR EXCHANGE           ', scheme%SR_EXCHANGE
WRITE(IUNIT,'(3X,A22,L7)') 'CAM                   ', scheme%CAM
WRITE(IUNIT,'(3X,A22,G14.2)') 'CAMalpha              ', scheme%CAMalpha
WRITE(IUNIT,'(3X,A22,G14.2)') 'CAMbeta               ', scheme%CAMbeta
WRITE(IUNIT,'(3X,A22,G14.2)') 'CAMmu                 ', scheme%CAMmu
WRITE(IUNIT,'(3X,A22,G14.2)') 'exchangeFactor        ', scheme%exchangeFactor
call WRITE_FORMATTET_DFT_PARAM(IUNIT,scheme%DFT)
WRITE(IUNIT,'(3X,A22,L7)')'INCREMENTAL           ', scheme%INCREMENTAL
WRITE(IUNIT,'(3X,A22,L7)')'DO_PROP               ', scheme%DO_PROP
WRITE(IUNIT,'(3X,A22,I7)')'PropOper              ', scheme%PropOper
END SUBROUTINE typedef_printScheme

!> \brief Transform AO Fock matrix to GCAO matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param MAT Matrix to be transformed
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine AO2GCAO_transform_matrixF(F,setting,lupri)
implicit none
integer,intent(in) :: lupri
type(matrix) :: F
TYPE(LSSETTING) :: setting
!
integer :: nrow,ncol
type(Matrix) :: wrk,CC
real(realk),pointer :: CCfull(:,:)

nrow = F%nrow
ncol = F%ncol
IF(ncol.NE.nrow)THEN
   call lsquit('AO2GCAO_transform_matrixF requires a square matrix',lupri)
ENDIF
call mem_alloc(CCfull,nrow,ncol)
!FIXME - build special case for CSR 
call read_GCtransformationmatrix(CCfull,nrow,setting,lupri)
call mat_init(CC,ncol,nrow)
IF(matrix_type .EQ. mtype_unres_dense)THEN
   CALL DCOPY(nrow*ncol,CCfull,1,CC%elms,1)
   CALL DCOPY(nrow*ncol,CCfull,1,CC%elmsb,1)
ELSE
   call mat_set_from_full(CCfull,1E0_realk,CC)
ENDIF
call mem_dealloc(CCfull)
call MAT_INIT(wrk,nrow,ncol)
call mat_mul(CC,F,'t','n',1E0_realk,0E0_realk,wrk)
call mat_mul(wrk,CC,'n','n',1E0_realk,0E0_realk,F)
call MAT_free(wrk)
call MAT_free(CC)

end subroutine AO2GCAO_transform_matrixF

!> \brief Half-transform AO matrix to GCAO matrix
!> \author S. Reine
!> \date Dec 6th 2012
!> \param MAT Matrix to be transformed
!> \param setting the setting structure
!> \param lupri the logical unit number for output
!> \param side index indicating if first or second AO should be transformed (1 or 2)
subroutine AO2GCAO_half_transform_matrix(F,setting,lupri,side)
implicit none
integer,intent(in) :: lupri
type(matrix)       :: F
TYPE(LSSETTING)    :: setting
Integer            :: side
!
integer :: nrow,ncol,ngcao
type(Matrix) :: wrk,CC
real(realk),pointer :: CCfull(:,:)

nrow = F%nrow
ncol = F%ncol
IF (side.EQ.1) THEN
  ngcao = nrow
ELSEIF (side.EQ.2) THEN
  ngcao = ncol
ELSE
  CALL lsquit('Error in AO2GCAO_half_transform_matrix. Incorrect side.',lupri)
ENDIF


call mem_alloc(CCfull,ngcao,ngcao)
!FIXME - build special case for CSR 
call read_GCtransformationmatrix(CCfull,ngcao,setting,lupri)
call mat_init(CC,ngcao,ngcao)
IF(matrix_type .EQ. mtype_unres_dense)THEN
   CALL DCOPY(ngcao*ngcao,CCfull,1,CC%elms,1)
   CALL DCOPY(ngcao*ngcao,CCfull,1,CC%elmsb,1)
ELSE
   call mat_set_from_full(CCfull,1E0_realk,CC)
ENDIF
call mem_dealloc(CCfull)

call MAT_INIT(wrk,nrow,ncol)
IF (side.EQ.1) THEN
  call mat_mul(CC,F,'t','n',1E0_realk,0E0_realk,wrk)
ELSE
  call mat_mul(F,CC,'n','n',1E0_realk,0E0_realk,wrk)
ENDIF
call mat_copy(1E0_realk,wrk,F)
call MAT_free(wrk)
call MAT_free(CC)

end subroutine AO2GCAO_half_transform_matrix

!> \brief Transform GCAO Density matrix to AO Density matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param MAT Matrix to be transformed
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine GCAO2AO_transform_matrixD(DMAT,setting,lupri)
implicit none
integer,intent(in) :: lupri
type(matrix) :: DMAT
TYPE(LSSETTING) :: setting
!
integer :: ndmat,nbast
real(realk),pointer :: DfullGCAO(:,:,:),DfullAO(:,:,:)
nbast=DMAT%nrow
IF(matrix_type .EQ. mtype_unres_dense)THEN
   ndmat = 2
   call mem_alloc(DfullGCAO,DMAT%nrow,DMAT%ncol,2)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DMAT%elms,1,DfullGCAO(:,:,1),1)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DMAT%elmsb,1,DfullGCAO(:,:,2),1)
ELSE
   ndmat = 1
   call mem_alloc(DfullGCAO,DMAT%nrow,DMAT%ncol,1)
   call mat_to_full(DMAT,1E0_realk,DfullGCAO(:,:,1))
ENDIF
call mem_alloc(DfullAO,DMAT%nrow,DMAT%ncol,ndmat)
call GCAO2AO_transform_fullD(DfullGCAO,DfullAO,nbast,ndmat,setting,lupri)
call mem_dealloc(DfullGCAO)
IF(matrix_type .EQ. mtype_unres_dense)THEN
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DfullAO(:,:,1),1,DMAT%elms,1)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DfullAO(:,:,2),1,DMAT%elmsb,1)
ELSE
   call mat_set_from_full(DfullAO,1E0_realk,DMAT)
ENDIF
call mem_dealloc(DfullAO)

end subroutine GCAO2AO_transform_matrixD

!> \brief Transform GCAO Density matrix to AO Density matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param MAT Matrix to be transformed
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine GCAO2AO_transform_matrixD2(DMATGCAO,DMATAO,setting,lupri)
implicit none
integer,intent(in) :: lupri
type(matrix) :: DMATGCAO,DMATAO
TYPE(LSSETTING) :: setting
!
integer :: ndmat,nbast
real(realk),pointer :: DfullGCAO(:,:,:),DfullAO(:,:,:)
nbast=DMATGCAO%nrow
IF(matrix_type .EQ. mtype_unres_dense)THEN
   ndmat = 2
   call mem_alloc(DfullGCAO,DMATGCAO%nrow,DMATGCAO%ncol,2)
   CALL DCOPY(DMATGCAO%nrow*DMATGCAO%ncol,DMATGCAO%elms,1,DfullGCAO(:,:,1),1)
   CALL DCOPY(DMATGCAO%nrow*DMATGCAO%ncol,DMATGCAO%elmsb,1,DfullGCAO(:,:,2),1)
ELSE
   ndmat = 1
   call mem_alloc(DfullGCAO,DMATGCAO%nrow,DMATGCAO%ncol,1)
   call mat_to_full(DMATGCAO,1E0_realk,DfullGCAO(:,:,1))
ENDIF
call mem_alloc(DfullAO,DMATAO%nrow,DMATAO%ncol,ndmat)
call GCAO2AO_transform_fullD(DfullGCAO,DfullAO,nbast,ndmat,setting,lupri)
call mem_dealloc(DfullGCAO)
IF(matrix_type .EQ. mtype_unres_dense)THEN
   CALL DCOPY(DMATAO%nrow*DMATAO%ncol,DfullAO(:,:,1),1,DMATAO%elms,1)
   CALL DCOPY(DMATAO%nrow*DMATAO%ncol,DfullAO(:,:,2),1,DMATAO%elmsb,1)
ELSE
   call mat_set_from_full(DfullAO,1E0_realk,DMATAO)
ENDIF
call mem_dealloc(DfullAO)

end subroutine GCAO2AO_transform_matrixD2

!> \brief Transform AO Density matrix to GCAO Density matrix
!> \author T. Kjaergaard
!> \date 2010
!> \param MAT Matrix to be transformed
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine AO2GCAO_transform_matrixD(DMAT,setting,lupri)
implicit none
integer,intent(in) :: lupri
type(matrix) :: DMAT
TYPE(LSSETTING) :: setting
!
integer :: ndmat,nbast
real(realk),pointer :: DfullGCAO(:,:,:),DfullAO(:,:,:)
nbast = DMAT%nrow
IF(matrix_type .EQ. mtype_unres_dense)THEN
   ndmat = 2
   call mem_alloc(DfullAO,DMAT%nrow,DMAT%ncol,ndmat)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DMAT%elms,1,DfullAO(:,:,1),1)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DMAT%elmsb,1,DfullAO(:,:,2),1)
ELSE
   ndmat = 1
   call mem_alloc(DfullAO,DMAT%nrow,DMAT%ncol,ndmat)
   call mat_to_full(DMAT,1E0_realk,DfullAO(:,:,1))
ENDIF
call mem_alloc(DfullGCAO,DMAT%nrow,DMAT%ncol,ndmat)
call AO2GCAO_transform_fullD(DfullAO,DfullGCAO,nbast,ndmat,setting,lupri)
call mem_dealloc(DfullAO)
IF(matrix_type .EQ. mtype_unres_dense)THEN
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DfullGCAO(:,:,1),1,DMAT%elms,1)
   CALL DCOPY(DMAT%nrow*DMAT%ncol,DfullGCAO(:,:,2),1,DMAT%elmsb,1)
ELSE
   call mat_set_from_full(DfullGCAO,1E0_realk,DMAT)
ENDIF
call mem_dealloc(DfullGCAO)

end subroutine AO2GCAO_transform_matrixD

!> \brief Transform 2 dim fortran array from AO to GCAO
!> \author T. Kjaergaard
!> \date 2010
!> \param fullMAT array to be transformed
!> \param nbast number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
!> This one works for S,F,H1 and other matrices that transform in the same way
!> For D se next routine
subroutine AO2GCAO_transform_fullF(fullMAT,nbast,setting,lupri)
implicit none
integer,intent(in) :: lupri,nbast
real(realk) :: fullMAT(nbast,nbast)
TYPE(LSSETTING) :: setting
!
real(realk),pointer :: CCfull(:,:)
real(realk),pointer :: WRK(:,:)

call mem_alloc(CCfull,nbast,nbast)
call read_GCtransformationmatrix(CCfull,nbast,setting,lupri)
call mem_alloc(wrk,nbast,nbast)
call DGEMM('t','n',nbast,nbast,nbast,1E0_realk,&
     &CCfull,nbast,fullMAT,nbast,0E0_realk,WRK,nbast)
call DGEMM('n','n',nbast,nbast,nbast,1E0_realk,&
     &WRK,nbast,CCfull,nbast,0E0_realk,fullMAT,nbast)

call mem_dealloc(wrk)
call mem_dealloc(CCfull)

end subroutine AO2GCAO_transform_fullF

!> \brief Transform Density from AO to GCAO
!> \author T. Kjaergaard
!> \date 2010
!> \param fullMAT array to be transformed
!> \param nbast number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
!> This one works for the density matrix and matrices that transform in the same way
!> For S,F,H1  se previous routine
subroutine AO2GCAO_transform_fullD(DmatAO,DmatGCAO,nbast,ndmat,setting,lupri)
implicit none
integer,intent(in) :: lupri,nbast,ndmat
real(realk) :: DmatAO(nbast,nbast,ndmat)
real(realk) :: DmatGCAO(nbast,nbast,ndmat)
TYPE(LSSETTING) :: setting
!
integer :: i
integer,pointer :: IPVT(:)
real(realk) :: dummy(2),RCOND
real(realk),pointer :: CCfull_inv(:,:),WRK(:,:),WORK1(:)

call mem_alloc(CCfull_inv,nbast,nbast)
call read_GCtransformationmatrix(CCfull_inv,nbast,setting,lupri)
!======build inverse==========================================
call mem_alloc(IPVT,nbast)
call mem_alloc(WORK1,nbast)
IPVT = 0; RCOND = 0E0_realk; dummy = 0E0_realk
call DGECO(CCfull_inv,nbast,nbast,IPVT,RCOND,work1)
call DGEDI(CCfull_inv,nbast,nbast,IPVT,dummy,work1,01)!01=inverse only
call mem_dealloc(IPVT)
call mem_dealloc(WORK1)
!=============================================================
call mem_alloc(WRK,nbast,nbast)
DO I=1,ndmat
   call DGEMM('n','n',nbast,nbast,nbast,1E0_realk,&
        &CCfull_inv,nbast,DmatAO(:,:,I),nbast,0E0_realk,WRK,nbast)
   call DGEMM('n','t',nbast,nbast,nbast,1E0_realk,&
        &WRK,nbast,CCfull_inv,nbast,0E0_realk,DmatGCAO(:,:,I),nbast)
ENDDO
call mem_dealloc(WRK)
call mem_dealloc(CCfull_inv)

end subroutine AO2GCAO_transform_fullD

!> \brief Transform GCAO 3dim fortran array to AO
!> \author T. Kjaergaard
!> \date 2010
!>
!> This one works for S,F,H1 and other matrices that transform in the same way
!> For D se next routine
!>
!> \param MATGCAO GCAO array to be transformed
!> \param MATAO AO the output array
!> \param nbast number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine GCAO2AO_transform_fullF(MATGCAO,MATAO,nbast,ndmat,setting,lupri)
implicit none
integer,intent(in) :: lupri,ndmat,nbast
real(realk) :: MATGCAO(nbast,nbast,ndmat)
real(realk) :: MATAO(nbast,nbast,ndmat)
TYPE(LSSETTING) :: setting
!
integer :: I
integer,pointer :: IPVT(:)
real(realk) :: dummy(2),RCOND
real(realk),pointer :: CCfull_inv(:,:),WRK(:,:),WORK1(:)

call mem_alloc(CCfull_inv,nbast,nbast)
call read_GCtransformationmatrix(CCfull_inv,nbast,setting,lupri)
!======build inverse==========================================
call mem_alloc(IPVT,nbast)
call mem_alloc(WORK1,nbast)
IPVT = 0; RCOND = 0E0_realk; dummy = 0E0_realk
call DGECO(CCfull_inv,nbast,nbast,IPVT,RCOND,work1)
call DGEDI(CCfull_inv,nbast,nbast,IPVT,dummy,work1,01)!01=inverse only
call mem_dealloc(IPVT)
call mem_dealloc(WORK1)
!=============================================================
call mem_alloc(WRK,nbast,nbast)
DO I=1,ndmat
   call DGEMM('t','n',nbast,nbast,nbast,1E0_realk,&
        &CCfull_inv,nbast,matgcao(:,:,I),nbast,0E0_realk,WRK,nbast)
   call DGEMM('n','n',nbast,nbast,nbast,1E0_realk,&
        &WRK,nbast,CCfull_inv,nbast,0E0_realk,matao(:,:,I),nbast)
ENDDO
call mem_dealloc(WRK)
call mem_dealloc(CCfull_inv)

end subroutine GCAO2AO_transform_fullF

!> \brief Transform GCAO 3dim fortran array to AO
!> \author T. Kjaergaard
!> \date 2010
!>
!> This one works for D and other matrices that transform in the same way
!> For F,S,H1 se previous routine
!>
!> \param MATGCAO GCAO array to be transformed
!> \param MATAO AO the output array
!> \param nbast number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
subroutine GCAO2AO_transform_fullD(MATGCAO,MATAO,nbast,ndmat,setting,lupri)
implicit none
integer :: lupri,ndmat,nbast
real(realk) :: MATGCAO(nbast,nbast,ndmat)
real(realk) :: MATAO(nbast,nbast,ndmat)
TYPE(LSSETTING) :: setting
!
integer :: I
integer,pointer :: IPVT(:)
real(realk) :: dummy(2),RCOND
real(realk),pointer :: CCfull(:,:),WRK(:,:),WORK1(:)

call mem_alloc(CCfull,nbast,nbast)
call read_GCtransformationmatrix(CCfull,nbast,setting,lupri)
call mem_alloc(WRK,nbast,nbast)
DO I=1,ndmat
   call DGEMM('n','n',nbast,nbast,nbast,1E0_realk,&
        &CCfull,nbast,matgcao(:,:,I),nbast,0E0_realk,WRK,nbast)
   call DGEMM('n','t',nbast,nbast,nbast,1E0_realk,&
        &WRK,nbast,CCfull,nbast,0E0_realk,matao(:,:,I),nbast)
ENDDO
call mem_dealloc(WRK)
call mem_dealloc(CCfull)

end subroutine GCAO2AO_transform_fullD

!> \brief Build AO,GCAO transformation matrix CC(AO,GCAO)
!> \author T. Kjaergaard
!> \date 2010
!> \param CCfull the transformation matrix to be generated
!> \param nbast the dimension, the number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
SUBROUTINE build_GCtransformationmatrix(CCfull,nbast,setting,lupri)
implicit none
integer,intent(in)   :: lupri
integer,intent(in)   :: nbast
TYPE(LSSETTING) :: setting
!TYPE(MATRIX)    :: CC
real(realk),intent(inout) :: CCfull(nbast,nbast)
!
integer :: nbast1,R1,I,ICHARGE,type,iang,norb,II,JJ,isp
integer :: nOrbComp,cc1,cc2,ccJJ,ccII
real(realk),parameter :: D0=0E0_realk
real(realk),pointer :: TMP(:,:)
real(realk) :: TMPs
logical :: matrix_exsist

!this could be built directly into a coordinate form and then transformed into CSR !
!so introduced special case for CSR 
DO JJ=1,nbast
   DO II=1,nbast
      CCfull(II,JJ) = D0
   ENDDO
ENDDO

nbast1 = 0
R1 = setting%BASIS(1)%p%GCtrans%Labelindex
DO I=1,setting%MOLECULE(1)%p%natoms   
   IF(setting%MOLECULE(1)%p%ATOM(I)%pointcharge)cycle
   IF(R1.EQ.0)THEN
      ICHARGE = INT(setting%MOLECULE(1)%p%ATOM(I)%CHARGE)      
      type = setting%BASIS(1)%p%GCtrans%CHARGEINDEX(ICHARGE)
   ELSE
      type = setting%MOLECULE(1)%p%ATOM(I)%IDtype(R1)
   ENDIF
   do iang = 1,setting%BASIS(1)%p%GCtrans%ATOMTYPE(type)%nAngmom
      norb = setting%BASIS(1)%p%GCtrans%ATOMTYPE(type)%SHELL(iang)%segment(1)%ncol
      nOrbComp = (2*(iang-1))+1   !not true if cartesian
      call mem_alloc(TMP,norb,norb)
      DO JJ=1,norb
         DO II=1,norb
            TMP(II,JJ)=&
                 &setting%BASIS(1)%p%GCtrans%ATOMTYPE(type)%SHELL(iang)%segment(1)%elms(II+(JJ-1)*norb)
         ENDDO
      ENDDO
      nOrbComp = (2*(iang-1))+1   !not true if cartesian
      DO JJ=1,norb
         ccJJ = nbast1+(JJ-1)*nOrbComp
         DO II=1,norb
            ccII = nbast1+(II-1)*nOrbComp
            TMPs = TMP(II,JJ)
            do isp = 1,nOrbComp
               cc1 = isp+ccII
               cc2 = isp+ccJJ
               CCfull(cc1,cc2)=TMPs
            ENDDO
         ENDDO !II
      ENDDO !JJ
      call mem_dealloc(TMP)
      nbast1 = nbast1 + norb*nOrbComp
   ENDDO
enddo
IF(nbast1.NE.nbast)&
     & call lsquit('dim mismatch in build_GCtransformationmatrix',-1)
end SUBROUTINE build_GCtransformationmatrix

!> \brief Build AO,GCAO transformation matrix CC(AO,GCAO)
!> \author T. Kjaergaard
!> \date 2010
!> \param CCfull the transformation matrix to be generated
!> \param nbast the dimension, the number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
SUBROUTINE write_GCtransformationmatrix(nbast,setting,lupri)
implicit none
integer,intent(in)   :: lupri
integer   :: nbast
TYPE(LSSETTING) :: setting
!
real(realk),pointer :: CCfull(:,:)
logical :: matrix_exsist
integer :: GCAOtrans_lun

INQUIRE(file='GCAOtrans',EXIST=matrix_exsist) 
IF(matrix_exsist)then
   GCAOtrans_lun=-1
   call lsopen(GCAOtrans_lun,'GCAOtrans','OLD','UNFORMATTED')
   call lsclose(GCAOtrans_lun,'DELETE')
ENDIF
call mem_alloc(CCfull,nbast,nbast)
call build_GCtransformationmatrix(CCfull,nbast,setting,lupri)
GCAOtrans_lun = -1  !initialization
call lsopen(GCAOtrans_lun,'GCAOtrans','UNKNOWN','UNFORMATTED')
rewind GCAOtrans_lun
WRITE(GCAOtrans_lun) nbast
WRITE(GCAOtrans_lun) CCfull
!print*,'write_GCtransformationmatrix nbast',nbast
!call output(CCfull,1,nbast,1,nbast,nbast,nbast,1,6)
call lsclose(GCAOtrans_lun,'KEEP')
call mem_dealloc(CCfull)
end SUBROUTINE write_GCtransformationmatrix

!> \brief Build AO,GCAO transformation matrix CC(AO,GCAO)
!> \author T. Kjaergaard
!> \date 2010
!> \param CCfull the transformation matrix to be generated
!> \param nbast the dimension, the number of basis functions
!> \param setting the setting structure
!> \param lupri the logical unit number for output
SUBROUTINE read_GCtransformationmatrix(CCfull,nbast,setting,lupri)
implicit none
integer,intent(in)   :: lupri
integer,intent(in)   :: nbast
integer   :: nbast2
TYPE(LSSETTING) :: setting
real(realk),intent(inout) :: CCfull(nbast,nbast)
!
logical :: matrix_exsist
integer :: GCAOtrans_lun

INQUIRE(file='GCAOtrans',EXIST=matrix_exsist) 
IF(matrix_exsist)then
   GCAOtrans_lun = -1  !initialization
   call lsopen(GCAOtrans_lun,'GCAOtrans','OLD','UNFORMATTED')
   rewind GCAOtrans_lun
   READ(GCAOtrans_lun) nbast2
   IF(nbast2.NE.nbast)call lsquit('dim mismatch read_GCtransformationmatrix',-1)
   READ(GCAOtrans_lun) CCfull
   call lsclose(GCAOtrans_lun,'KEEP')
ELSE
   call build_GCtransformationmatrix(CCfull,nbast,setting,lupri)
ENDIF
!print*,'read_GCtransformationmatrix nbast',nbast
!call output(CCfull,1,nbast,1,nbast,nbast,nbast,1,6)
end SUBROUTINE read_GCtransformationmatrix

!> \brief copy ls to newls 
!> \author Branislav Jansik
!> \date 2010-03-03
!> \param ls lsitem structure containing full integral,molecule,basis info
!> \param minls lsitem structure containing valens integral,molecule,basis info
SUBROUTINE alloc_sync_ls(newls,ls)
implicit none
TYPE(LSITEM) :: newls,ls

  call alloc_sync_daltoninput(newls%input,ls%input,ls%lupri)
  call copy_setting(newls%setting,ls%setting,ls%lupri)
!  call typedef_init_setting(newls%setting)
!  call typedef_set_default_setting(newls%setting,newls%input)
  newls%lupri = ls%lupri
  newls%luerr = ls%luerr
END SUBROUTINE alloc_sync_ls

!> \brief 
!> \author Branislav Jansik
!> \date 2010-03-03
!> \param 
!> \param 
!> \param 
!> \param 
!> \param 
SUBROUTINE alloc_sync_daltoninput(NDALTON,DALTON,lupri)
IMPLICIT NONE
TYPE(daltoninput) :: DALTON
TYPE(daltoninput) :: NDALTON
integer :: lupri
!TYPE(daltonitem),pointer :: NDALTON(:)

! STRUCTURE
  NDALTON = DALTON
  !ALL STRUCTURES IN THIS STRUCTURE LIKE, THE DALTONITEM IS COPIED BY THIS
  !LINE, ALTHOUGH ALL STRUCTURES WHICH INCLUDES POINTERS ARE NOT COPIED CORRECTLY
  !WE THEREFORE NEED TO ALLOCATE ALL THE POINTERS AND THEN COPY THE CONTENT OF
  ! THESE POINTERS 

! THE MOLECULE  (CONTAINS THE POINTER MOLECULEINFO%ATOM)
  NULLIFY(NDALTON%MOLECULE)
  ALLOCATE(NDALTON%MOLECULE)
  NULLIFY(NDALTON%BASIS)
  ALLOCATE(NDALTON%BASIS)
  NDALTON%MOLECULE = DALTON%MOLECULE
  NDALTON%BASIS = DALTON%BASIS
  !AND NOW COPY THE MOLECULEINFO%ATOM
  call mem_alloc(NDALTON%MOLECULE%ATOM,DALTON%MOLECULE%nAtoms)
  NDALTON%MOLECULE%ATOM = DALTON%MOLECULE%ATOM
  
  !THE SAME IS DONE FOR THE BASISSETINFO 
  CALL ALLOC_SYNC_BASISSETINFO(NDALTON%BASIS%REGULAR,DALTON%BASIS%REGULAR)
  CALL ALLOC_SYNC_BASISSETINFO(NDALTON%BASIS%AUXILIARY,DALTON%BASIS%AUXILIARY)
  CALL ALLOC_SYNC_BASISSETINFO(NDALTON%BASIS%CABS,DALTON%BASIS%CABS)
  CALL ALLOC_SYNC_BASISSETINFO(NDALTON%BASIS%JK,DALTON%BASIS%JK)
  CALL ALLOC_SYNC_BASISSETINFO(NDALTON%BASIS%VALENCE,DALTON%BASIS%VALENCE)

  !AND THE BLOCK STRUCTURES - BUT THIS IS ONLY USED IN INTEGRAL EVALUATION
!  NULLIFY(NDALTON%LHSblock%blocks)
!  ALLOCATE(NDALTON%LHSblock%blocks(DALTON%LHSblock%numBlocks))
!  NDALTON%LHSblock%blocks = DALTON%LHSblock%blocks
!  NULLIFY(NDALTON%RHSblock%blocks)
!  ALLOCATE(NDALTON%RHSblock%blocks(DALTON%RHSblock%numBlocks))
!  NDALTON%RHSblock%blocks = DALTON%RHSblock%blocks

  WRITE(lupri,*)'the New daltoninput structure'
  call PRINT_DALTONINPUT(NDALTON,LUPRI)
  WRITE(lupri,*)'the Old daltoninput structure'
  call PRINT_DALTONINPUT(DALTON,LUPRI)

END SUBROUTINE ALLOC_SYNC_DALTONINPUT

SUBROUTINE alloc_sync_BASISSETINFO(NBASISINFO,BASISINFO)
IMPLICIT NONE
TYPE(BASISSETINFO) :: BASISINFO,NBASISINFO
INTEGER            :: I,J,K,L,nrow,nsize,icharge,maxcharge,ncol
  IF (BASISINFO%natomtypes.eq. 0) THEN
     NBASISINFO%natomtypes=0
     return
  ENDIF
  NBASISINFO%natomtypes = BASISINFO%natomtypes
  NULLIFY(NBASISINFO%ATOMTYPE)
  call mem_alloc(NBASISINFO%ATOMTYPE,BASISINFO%natomtypes)
  NBASISINFO%ATOMTYPE = BASISINFO%ATOMTYPE  
  maxcharge = 0
  NBASISINFO%nAtomtypes = BASISINFO%nAtomtypes
  DO J=1,BASISINFO%nAtomtypes
     icharge = BASISINFO%ATOMTYPE(J)%charge
     maxcharge = MAX(maxcharge,icharge)
     !NO need to alloc SHELL
     NBASISINFO%ATOMTYPE(J)%nAngmom = &
          &BASISINFO%ATOMTYPE(J)%nAngmom
     DO K=1,BASISINFO%ATOMTYPE(J)%nAngmom
        !NO need to alloc segments
        NBASISINFO%ATOMTYPE(J)%SHELL(K)%nsegments = &
             &BASISINFO%ATOMTYPE(J)%SHELL(K)%nsegments
        DO L=1,BASISINFO%ATOMTYPE(J)%SHELL(K)%nsegments
           nrow=BASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%nrow
           ncol=BASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%ncol
           nsize=nrow*ncol
           call mem_alloc(NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%elms,nSIZE)
           call mem_alloc(NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%Exponents,nrow)
           NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%elms(:) = &
                & BASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%elms(:)
           NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%Exponents(:) = &
                & BASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%Exponents(:)
           NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%nrow = nrow
           NBASISINFO%ATOMTYPE(J)%SHELL(K)%segment(L)%ncol = ncol 
        ENDDO
     ENDDO
  ENDDO
  NBASISINFO%labelindex = BASISINFO%labelindex
  IF(BASISINFO%labelindex.EQ. 0)THEN
     IF(BASISINFO%nchargeindex.NE. 0)THEN
        call mem_alloc(NBASISINFO%chargeindex,BASISINFO%nchargeindex,.TRUE.)
        NBASISINFO%nchargeindex = BASISINFO%nchargeindex
        NBASISINFO%chargeindex(0:BASISINFO%nchargeindex) = &
             &BASISINFO%chargeindex(0:BASISINFO%nchargeindex)
     ELSE
        NBASISINFO%nchargeindex = 0
     ENDIF
  ELSE
     NBASISINFO%nchargeindex = 0
  ENDIF

END SUBROUTINE ALLOC_SYNC_BASISSETINFO

SUBROUTINE print_reduced_screening_info(redCS,iprint,iunit)
implicit none
TYPE(ReducedScreeningInfo),intent(IN) :: redCS
Integer,intent(IN)                    :: iprint,iunit
!
integer :: iAO
logical :: doall

IF (iprint.GE.1) THEN
  WRITE(IUNIT,'(A,I4)') 'Printing reduced screening information with print level',iprint
  IF (redCS%isset) THEN
#ifdef VAR_LSMPI
    WRITE(IUNIT,'(A,G10.4)') 'Screening threshold is ',(1E1_realk)**redCS%CS_THRLOG
    DO iAO=1,4
      IF (IPRINT.GE.5) write(IUNIT,'(3X,A,I1)') 'Printing AO item info for iAO ',iAO
      call print_aoAtomInfo(redCS%AO(iAO),iprint,iunit)
    ENDDO
    IF (iprint.GE.10) THEN
      doall = iprint.GE.20
      IF(associated(redCS%LHSGAB))THEN
         write(IUNIT,'(3X,A,2I6)') 'Printing LHSGAB  dim:',redCS%nbatches(1),redCS%nbatches(2)
         write(IUNIT,'(3X,A,I6)') 'maxgab LHS:',redCS%maxgabLHS
         call shortint_output(redCS%LHSGAB,redCS%nbatches(1),redCS%nbatches(2),iunit)
      ENDIF
      IF(associated(redCS%RHSGAB))THEN
         write(IUNIT,'(3X,A,2I6)') 'Printing RHSGAB  dim:',redCS%nbatches(3),redCS%nbatches(4)
         write(IUNIT,'(3X,A,I6)') 'maxgab RHS:',redCS%maxgabRHS
         call shortint_output(redCS%RHSGAB,redCS%nbatches(3),redCS%nbatches(4),iunit)
      ENDIF
      IF (redCS%LHSDMATset) THEN
        write(IUNIT,'(3X,A)') 'Printing LHSDMAT  dim:',redCS%nbatches(1),redCS%nbatches(2)
        write(IUNIT,'(3X,A,I6)') 'maxDmat LHS:',redCS%maxDmatLHS
        call shortint_output(redCS%LHSDMAT,redCS%nbatches(1),redCS%nbatches(2),iunit)   
      ELSE
        write(IUNIT,'(3X,A)') 'LHSDMAT not set'
      ENDIF
      IF (redCS%RHSDMATset) THEN
        write(IUNIT,'(3X,A)') 'Printing RHSDMAT  dim:',redCS%nbatches(3),redCS%nbatches(4)
        write(IUNIT,'(3X,A,I6)') 'maxDmat RHS:',redCS%maxDmatRHS
        call shortint_output(redCS%RHSDMAT,redCS%nbatches(3),redCS%nbatches(4),iunit)

      ELSE
        write(IUNIT,'(3X,A)') 'RHSDMAT not set'
      ENDIF
    ENDIF
#else
    CALL LSQUIT('Error in print_reduced_screening_info. redCS%isset for non-MPI run',-1)
#endif
  ELSE
    WRITE(IUNIT,'(3X,A)') 'Reduced screening information has not been set'
  ENDIF
ENDIF
END SUBROUTINE print_reduced_screening_info

#ifdef VAR_LSMPI
SUBROUTINE print_aoAtomInfo(AO,iprint,iunit)
implicit none
TYPE(aoAtomInfo),intent(IN) :: AO
Integer,intent(IN)          :: iprint,iunit
!
Integer :: iAtom
!
IF (iprint.GE.2) THEN
  WRITE(IUNIT,'(5X,A,I7)') 'Total number of atoms  ',AO%nAtoms
  WRITE(IUNIT,'(5X,A,I7)') 'Total number of batches',AO%nTotBatch
  IF (iprint.GE.10) THEN
    DO iAtom=1,AO%nAtoms
      WRITE(IUNIT,'(7X,A,I7)') 'Printing batch information for iAtom',iAtom
      call print_aoBatchInfo(AO%batch(iAtom),iprint,iunit)
    ENDDO
  ENDIF
ENDIF
END SUBROUTINE print_aoAtomInfo

SUBROUTINE print_aoBatchInfo(batch,iprint,iunit)
TYPE(aoBatchInfo),intent(IN) :: batch
Integer,intent(IN)          :: iprint,iunit
!
Integer :: i
!
WRITE(IUNIT,'(9X,A,I3)') 'Number of batches',batch%nBatches
IF (iprint.GE.20) THEN
  WRITE(IUNIT,'(9X,A7,8I3 / 16X,8I3)') 'nPrim  ',(batch%nprim(i),i=1,batch%nBatches)
  WRITE(IUNIT,'(9X,A7,8I3 / 16X,8I3)') 'maxAng ',(batch%maxAng(i),i=1,batch%nBatches)
ENDIF
END SUBROUTINE print_aoBatchInfo
#endif

SUBROUTINE copy_reduced_screening_info(newRedCS,oldRedCS)
implicit none
TYPE(ReducedScreeningInfo),intent(INOUT) :: newRedCS
TYPE(ReducedScreeningInfo),intent(IN)    :: oldRedCS
!
Integer :: iAO
!
#ifdef VAR_LSMPI
  CALL init_reduced_screen_info(newRedCS)
  newRedCS%isset = oldRedCS%isset
  IF (newRedCS%isset) THEN
     CALL LSQUIT('Error in copy_reduced_screening_info. newRedCS isset not implemented in copy_reduced_screening_info',-1)
!ToDO
!   DO iAO=1,4
!     call init_aobatchinfo(newRedCS%AO(iAO))
!     call copy_aobatchinfo(newRedCS%AO(iAO),oldRedCS%AO(iAO))
!   ENDDO
!   IF (associated(oldRedCS%LHSGAB)) THEN
!     CALL lstensor_copy()
!   ENDIF
  ENDIF
#else
  IF (oldRedCS%isset) CALL LSQUIT('Error in copy_reduced_screening_info. oldRedCS isset for non-MPI run',-1)
  CALL init_reduced_screen_info(newRedCS)
#endif
END SUBROUTINE copy_reduced_screening_info

SUBROUTINE init_reduced_screen_info(redCS)
implicit none
TYPE(ReducedScreeningInfo),intent(INOUT) :: redCS
!
integer :: iAO
!
redCS%isset = .FALSE.
#ifdef VAR_LSMPI
redCS%CS_THRLOG = shortzero
DO iAO=1,4
  call init_aoAtomInfo(redCS%AO(iAO))
ENDDO
redCS%LHSDMATset = .FALSE.
redCS%RHSDMATset = .FALSE.
nullify(redCS%LHSDMAT)
nullify(redCS%RHSDMAT)
nullify(redCS%LHSGAB)
nullify(redCS%RHSGAB)
redCS%maxgabrhs = shortzero
redCS%maxgablhs = shortzero
#endif
END SUBROUTINE init_reduced_screen_info

#ifdef VAR_LSMPI
SUBROUTINE init_aoAtomInfo(AO)
implicit none
TYPE(aoAtomInfo),intent(INOUT) :: AO
AO%nAtoms    = 0
AO%nTotBatch = 0
NULLIFY(AO%batch)
END SUBROUTINE init_aoAtomInfo
#endif

SUBROUTINE free_reduced_screen_info(redCS)
implicit none
TYPE(ReducedScreeningInfo),intent(INOUT) :: redCS
!
integer :: iAO
!
IF (redCS%isset) THEN
#ifdef VAR_LSMPI
  redCS%isset = .FALSE.
  redCS%CS_THRLOG = shortzero
  DO iAO=1,4
    call free_aoAtomInfo(redCS%AO(iAO))
  ENDDO
  IF(associated(redCS%LHSGAB))THEN
!     DEALLOCATE(redCS%LHSGAB)
     NULLIFY(redCS%LHSGAB)
     redCS%maxgabLHS = shortzero
  ENDIF
  IF(associated(redCS%RHSGAB))THEN
!     DEALLOCATE(redCS%RHSGAB)
     NULLIFY(redCS%RHSGAB)
     redCS%maxgabRHS = shortzero
  ENDIF
  IF (redCS%LHSDMATset) THEN
     call mem_dealloc(redCS%LHSDMAT)
     redCS%LHSDMATset = .FALSE.
  ENDIF
  IF (redCS%RHSDMATset) THEN
     call mem_dealloc(redCS%RHSDMAT)
     redCS%RHSDMATset = .FALSE.
  ENDIF
#else
  CALL LSQUIT('Error in free_reduced_screening_info. isset true for non-MPI run',-1)
#endif
ENDIF
END SUBROUTINE free_reduced_screen_info

#ifdef VAR_LSMPI
SUBROUTINE free_aoAtomInfo(AO)
implicit none
TYPE(aoAtomInfo),intent(INOUT) :: AO
!
Integer :: iAtom
DO iAtom=1,AO%nAtoms
  call free_aobatchinfo(AO%batch(iAtom))
ENDDO
DEALLOCATE(AO%batch)
NULLIFY(AO%batch)
AO%nAtoms = 0
AO%nTotBatch = 0
END SUBROUTINE free_aoAtomInfo

SUBROUTINE free_aobatchinfo(aobatch)
implicit none
TYPE(aoBatchInfo),intent(INOUT) :: aobatch
aobatch%nBatches = 0
call mem_dealloc(aobatch%nPrim)
call mem_dealloc(aobatch%maxAng)
END SUBROUTINE free_aobatchinfo
#endif

!> \brief create a list to convert valence to full
!> \author Branislav Jansik
!> \date 2010-03-03
!> \param list 
!> \param vlist 
!> \param len
!> \param ls lsitem structure containing full integral,molecule,basis info
!> \param vbasis valence basis
subroutine typedef_setlist_valence2full(list,vlist,len,ls,vbasis)
implicit none
TYPE(lsitem), intent(in)      :: ls
type(basissetinfo)            :: vbasis
integer, pointer              :: vlist(:,:), list(:,:)
integer, intent(out)          :: len
!
integer :: nAtoms, nAngmom, vnAngmom, norb, ipos, charge
integer :: itype, ang, i,j,k, kmult, icharge
integer :: istart, iend, vistart, viend, vnorb

 nAtoms = ls%input%MOLECULE%nAtoms

 len = 0
 do i=1, nAtoms
    IF(ls%input%MOLECULE%ATOM(i)%pointcharge)CYCLE
    IF(vbasis%labelindex .EQ. 0)THEN
       icharge = INT(ls%input%MOLECULE%ATOM(i)%charge) 
       itype = ls%input%BASIS%REGULAR%chargeindex(icharge)
    ELSE
       itype = ls%input%MOLECULE%ATOM(i)%IDtype(1)
    ENDIF

    nAngmom = vbasis%ATOMTYPE(itype)%nAngmom
    
    len = len + nAngmom
 enddo

 call mem_alloc(list,len,2)
 call mem_alloc(vlist,len,2)

 istart = 1; vistart=1; k=1
 do i=1, nAtoms
    IF(ls%input%MOLECULE%ATOM(i)%pointcharge)CYCLE
    IF(vbasis%labelindex .EQ. 0)THEN
       icharge = INT(ls%input%MOLECULE%ATOM(i)%charge) 
       itype = ls%input%BASIS%REGULAR%chargeindex(icharge)
    ELSE
       itype = ls%input%MOLECULE%ATOM(i)%IDtype(1)
    ENDIF

      vnAngmom = vbasis%ATOMTYPE(itype)%nAngmom
       nAngmom = ls%input%BASIS%REGULAR%ATOMTYPE(itype)%nAngmom

      kmult = 1
      do ang = 0,vnAngmom-1
         norb = ls%input%BASIS%REGULAR%ATOMTYPE(itype)%SHELL(ang+1)%norb
        vnorb = vbasis%ATOMTYPE(itype)%SHELL(ang+1)%norb

         iend =  istart  + (vnorb*kmult) -1
        viend = vistart  + (vnorb*kmult) -1

         list(k,1)=  istart;   list(k,2)=  iend
        vlist(k,1)= vistart;  vlist(k,2)= viend

         k = k + 1
         istart =  istart + (norb*kmult)
        vistart = viend + 1
         kmult = kmult + 2
      enddo

      do ang=vnAngmom, nAngmom-1
         norb =  ls%input%BASIS%REGULAR%ATOMTYPE(itype)%SHELL(ang+1)%norb
         istart = istart + (norb*kmult)
         kmult = kmult +2
      enddo

 enddo

end subroutine typedef_setlist_valence2full


!> Count number of core orbitals
integer function count_ncore(ls)
implicit none
TYPE(lsitem) , intent(in)    :: ls
integer :: ncore, i, icharge,nAtoms

  ncore=0

  nAtoms= ls%setting%MOLECULE(1)%p%nAtoms

  do i=1,nAtoms
  
    icharge = INT(ls%setting%MOLECULE(1)%p%ATOM(i)%charge)
  
    if (icharge.gt. 2)  ncore = ncore + 1
    if (icharge.gt. 10) ncore = ncore + 4
    if (icharge.gt. 18) ncore = ncore + 4
    if (icharge.gt. 30) ncore = ncore + 6

  enddo

  count_ncore = ncore

  return

end function count_ncore



END MODULE TYPEDEF


