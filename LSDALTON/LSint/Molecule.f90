!> @file
!> Module containing subroutines related to the molecule

!> Standard molecule module. Contains also the orbital information.
!> \author S. Reine
!> \date 2010-02-21
MODULE molecule_module
use precision
use typedef
use memory_handling
use molecule_type
use integralparameters
CONTAINS


!*****************************************
!*
!*  BASISSETINFO INITIATION ROUTINES
!*
!*****************************************

!> \brief Returns number of atoms and regular and auxiliary orbitals of given molecule
!> \author S. Reine
!> \date 2010-02-21
!> \param molecule Contains the information about the molecule
!> \param nAtoms The number of atoms
!> \param nBastReg The number of regular orbitals
!> \param nBastAux The number of auxiliary orbitals
SUBROUTINE getMolecularDimensions(MOLECULE,nAtoms,nBast,nBastAux)
implicit none
TYPE(MOLECULEINFO),intent(in) :: MOLECULE
Integer,intent(out)           :: nAtoms,nBast,nBastAux
!AORdefault   !AODFdefault
nAtoms   = MOLECULE%nAtoms
IF(AORdefault.EQ.AOregular)THEN
   nbast = MOLECULE%nbastREG
ELSEIF(AORdefault.EQ.AOVAL)THEN
   nbast = MOLECULE%nbastVAL
ELSEIF(AORdefault.EQ.AOdfAux)THEN
   nBastAux = MOLECULE%nBastAUX
ELSEIF(AORdefault.EQ.AOdfCABS)THEN
   nBastAux = MOLECULE%nBastCABS
ELSEIF(AORdefault.EQ.AOdfJK)THEN
   nBastAux = MOLECULE%nBastJK
ELSE   
   CALL LSQUIT('ERROR IN NBASIS DETERMINATION in getMolecularDimensions',-1)
ENDIF

IF(AODFdefault.EQ.AOregular)THEN
   nbast = MOLECULE%nbastREG
ELSEIF(AODFdefault.EQ.AOVAL)THEN
   nbast = MOLECULE%nbastVAL
ELSEIF(AODFdefault.EQ.AOdfAux)THEN
   nBastAux = MOLECULE%nBastAUX
ELSEIF(AODFdefault.EQ.AOdfCABS)THEN
   nBastAux = MOLECULE%nBastCABS
ELSEIF(AODFdefault.EQ.AOdfJK)THEN
   nBastAux = MOLECULE%nBastJK
ELSE
   CALL LSQUIT('ERROR IN NAUX DETERMINATION in getMolecularDimensions',-1)
ENDIF
!
END SUBROUTINE getMolecularDimensions

!> \brief Sets up the orbital information for a given molecule
!> \author S. Reine
!> \date 2010-02-21
!> \param Molecule Contains the information about the molecule
!> \param orbitalInfo Contains orbital indeces for the different atoms
SUBROUTINE setMolecularOrbitalInfo(MOLECULE,orbitalInfo)
implicit none
TYPE(MOLECULEINFO),intent(in)            :: MOLECULE
TYPE(MOLECULARORBITALINFO),intent(inout) :: orbitalInfo
!
integer :: iAtom,iReg,iAux,nOrbReg,nOrbAux


CALL getMolecularDimensions(MOLECULE,orbitalInfo%nAtoms,orbitalInfo%nBastReg,&
   &                        orbitalInfo%nBastAux)

CALL initMolecularOrbitalInfo(orbitalInfo,orbitalInfo%nAtoms)

iReg = 0
iAux = 0
DO iAtom=1,orbitalInfo%nAtoms
   IF(AORdefault.EQ.AOregular)THEN
      nOrbReg = MOLECULE%ATOM(iAtom)%nContOrbREG
   ELSEIF(AORdefault.EQ.AOVAL)THEN
      nOrbReg = MOLECULE%ATOM(iAtom)%nContOrbVAL
   ELSEIF(AORdefault.EQ.AOdfAux)THEN
      nOrbReg = MOLECULE%ATOM(iAtom)%nContOrbAUX
   ELSEIF(AORdefault.EQ.AOdfCABS)THEN
      nOrbReg = MOLECULE%ATOM(iAtom)%nContOrbCABS
   ELSEIF(AORdefault.EQ.AOdfJK)THEN
      nOrbReg = MOLECULE%ATOM(iAtom)%nContOrbJK
   ENDIF
   IF(AODFdefault.EQ.AOregular)THEN
      nOrbAux = MOLECULE%ATOM(iAtom)%nContOrbREG
   ELSEIF(AODFdefault.EQ.AOVAL)THEN
      nOrbAux = MOLECULE%ATOM(iAtom)%nContOrbVAL
   ELSEIF(AODFdefault.EQ.AOdfAux)THEN
      nOrbAux = MOLECULE%ATOM(iAtom)%nContOrbAUX
   ELSEIF(AODFdefault.EQ.AOdfCABS)THEN
      nOrbAux = MOLECULE%ATOM(iAtom)%nContOrbCABS
   ELSEIF(AODFdefault.EQ.AOdfJK)THEN
      nOrbAux = MOLECULE%ATOM(iAtom)%nContOrbJK
   ENDIF
   orbitalInfo%numAtomicOrbitalsReg(iAtom)=nOrbReg
   orbitalInfo%numAtomicOrbitalsAux(iAtom)=nOrbAux
   orbitalInfo%startAtomicOrbitalsReg(iAtom) = iReg+1
   orbitalInfo%startAtomicOrbitalsAux(iAtom) = iAux+1
   iReg = iReg + nOrbReg
   iAux = iAux + nOrbAux
   orbitalInfo%endAtomicOrbitalsReg(iAtom) = iReg
   orbitalInfo%endAtomicOrbitalsAux(iAtom) = iAux
ENDDO
END SUBROUTINE setMolecularOrbitalInfo

!> \brief Returns the orbital information of a given atom
!> \author S. Reine
!> \date 2010-02-19
!> \param orbitalInfo Contains the orbital-information of a given molecule
!> \param iAtom Specifies the atomic number in question
!> \param nReg The number of regular basis functions on given atom
!> \param startReg The starting orbital index of given atom
!> \param endReg The last orbital index of given atom
!> \param nAux The number of auxiliary basis functions on given atom
!> \param startAux The starting auxiliary orbital index of given atom
!> \param endAux The last auxiliary orbital index of given atom
SUBROUTINE getAtomicOrbitalInfo(orbitalInfo,iAtom,nReg,startReg,endReg,nAux,startAux,endAux)
use typedef
implicit none
TYPE(MOLECULARORBITALINFO),intent(IN) :: orbitalInfo
Integer,intent(IN)  :: iAtom
Integer,intent(OUT) :: nReg,startReg,endReg,nAux,startAux,endAux
!
nReg     = orbitalInfo%numAtomicOrbitalsReg(iAtom)
startReg = orbitalInfo%startAtomicOrbitalsReg(iAtom)
endReg   = orbitalInfo%endAtomicOrbitalsReg(iAtom)
nAux     = orbitalInfo%numAtomicOrbitalsAux(iAtom)
startAux = orbitalInfo%startAtomicOrbitalsAux(iAtom)
endAux   = orbitalInfo%endAtomicOrbitalsAux(iAtom)
!
END SUBROUTINE getAtomicOrbitalInfo

!> \brief Initialize orbitalInfo type
!> \author S. Reine
!> \date 2010-02-21
!> \param orbitalInfo Contains orbital indeces for the different atoms
!> \param nAtoms The number of atoms
SUBROUTINE initMolecularOrbitalInfo(orbitalInfo,nAtoms)
implicit none
TYPE(MOLECULARORBITALINFO),intent(inout) :: orbitalInfo
integer,intent(in)                       :: nAtoms

CALL mem_alloc(orbitalInfo%numAtomicOrbitalsReg,nAtoms)
CALL mem_alloc(orbitalInfo%startAtomicOrbitalsReg,nAtoms)
CALL mem_alloc(orbitalInfo%endAtomicOrbitalsReg,nAtoms)
CALL mem_alloc(orbitalInfo%numAtomicOrbitalsAux,nAtoms)
CALL mem_alloc(orbitalInfo%startAtomicOrbitalsAux,nAtoms)
CALL mem_alloc(orbitalInfo%endAtomicOrbitalsAux,nAtoms)

END SUBROUTINE initMolecularOrbitalInfo

 
!> \brief Frees orbitalInfo type
!> \author S. Reine
!> \date 2010-02-21
!> \param orbitalInfo Contains orbital indeces for the different atoms
SUBROUTINE freeMolecularOrbitalInfo(orbitalInfo)
implicit none
TYPE(MOLECULARORBITALINFO),INTENT(INOUT) :: orbitalInfo
!
CALL mem_dealloc(orbitalInfo%numAtomicOrbitalsReg)
CALL mem_dealloc(orbitalInfo%startAtomicOrbitalsReg)
CALL mem_dealloc(orbitalInfo%endAtomicOrbitalsReg)
CALL mem_dealloc(orbitalInfo%numAtomicOrbitalsAux)
CALL mem_dealloc(orbitalInfo%startAtomicOrbitalsAux)
CALL mem_dealloc(orbitalInfo%endAtomicOrbitalsAux)
END SUBROUTINE freeMolecularOrbitalInfo

!> \brief Determined the number of electrons for a given molecule
!> \author T. Kjaergaard
!> \date 2010-02-21
!> \param Molecule Contains the information about the molecule
!> \param Moleculecharge The charge of the molecule
!> \param nelectrons The number of electrons
SUBROUTINE DETERMINE_NELECTRONS(Molecule,Moleculecharge,nelectrons)
implicit none
TYPE(MOLECULEINFO),intent(IN) :: MOLECULE
real(realk),intent(IN)        :: Moleculecharge
integer,intent(OUT)           :: Nelectrons
!
integer :: I,NCHARGE

NCHARGE = 0
DO I = 1,MOLECULE%NATOMS
   IF(MOLECULE%ATOM(I)%phantom)CYCLE !no electrons on this  
   NCHARGE = INT(MOLECULE%ATOM(I)%CHARGE)+NCHARGE
ENDDO

NELECTRONS = NCHARGE - INT(Moleculecharge)

END SUBROUTINE DETERMINE_NELECTRONS

!> \brief Divide a molecule into molecular fragments (by setting up indices)
!> \author S. Reine
!> \date 2010-02-05
!> \param Molecule The molecule to be fragmented
!> \param fragmentIndex Indices specifying for each atom in Molecule which fragment it belongs to
!> \param numFragments The number of fragments the molecule should be divied into
!> \param lupri Default output unit
SUBROUTINE fragmentMolecule(Molecule,fragmentIndex,numFragments,lupri)
implicit none
TYPE(MOLECULEINFO),intent(in) :: MOLECULE
Integer,intent(in)            :: numFragments,lupri
Integer,intent(inout)         :: fragmentIndex(MOLECULE%nAtoms)
!
Integer :: numOrbitals,numFragOrbitals,iFragment,I,totOrb
logical :: Increased


IF (numFragments.GT.MOLECULE%nAtoms) THEN
  CALL LSQUIT('ERROR: fragmentMolecule entered with numFragments > nAtoms',lupri)
ELSEIF (numFragments.EQ.MOLECULE%nAtoms) THEN
  TOTorb=0
  iFragment = 0
  DO I=1,MOLECULE%nAtoms
    numOrbitals = MOLECULE%ATOM(I)%nContOrbREG
    TOTorb = TOTorb + MOLECULE%ATOM(I)%nContOrbREG
    iFragment = iFragment + 1
    fragmentIndex(I) = iFragment
  ENDDO
ELSE
! Divide the molecule into fragments with approximately similar number of
! orbitals

! First get the average number of orbitals per fragment
  numFragOrbitals = MOLECULE%nbastREG/numFragments

! Then partition the molecule into fragments of about this number of orbitails
  TOTorb=0
  numOrbitals = 0
  iFragment   = 1
  Increased = .FALSE.
  DO I=1,MOLECULE%nAtoms
    numOrbitals = numOrbitals + MOLECULE%ATOM(I)%nContOrbREG
    TOTorb = TOTorb + MOLECULE%ATOM(I)%nContOrbREG
    fragmentIndex(I) = iFragment
    Increased = .TRUE.
    IF((TOTorb .GE. iFragment*numFragOrbitals .AND. .NOT. (ifragment.EQ.numFragments) ))THEN
      iFragment = iFragment + 1
      numOrbitals = 0
      Increased = .FALSE.
    ENDIF
  ENDDO
  IF(.NOT.Increased) ifragment=ifragment-1
  IF(iFragment .NE. numFragments) THEN
     TOTorb=0
     numOrbitals = 0
     iFragment   = numFragments
     Increased = .FALSE.
     DO I=MOLECULE%nAtoms,1,-1
        numOrbitals = numOrbitals + MOLECULE%ATOM(I)%nContOrbREG
        TOTorb = TOTorb + MOLECULE%ATOM(I)%nContOrbREG
        fragmentIndex(I) = iFragment
        Increased = .TRUE.
        IF (TOTorb .GE. (numFragments-iFragment+1)*numFragOrbitals .AND. .NOT. ((numFragments-ifragment+1).EQ.numFragments)) THEN
           iFragment = iFragment - 1
           numOrbitals = 0
           Increased = .FALSE.
        ENDIF
     ENDDO
     IF(.NOT.Increased)ifragment=ifragment+1
     ifragment = numFragments-iFragment+1
  ENDIF
  IF(iFragment .NE. numFragments) THEN
     WRITE(LUPRI,*)'FRAGEMENT ',iFragment
     WRITE(LUPRI,*)'NODES     ',numFragments
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     WRITE(LUPRI,*)'WARNING WARNING WANING '
     CALL LSQUIT('ifrag not equal to number of nodes',lupri)
  ENDIF
ENDIF

END SUBROUTINE fragmentMolecule

!> \brief Builds a molecular fragment from a subset of the atoms in the original molecule
!> \author S. Reine and T. Kjaergaard
!> \date 2010-02-21
!> \param DALMOL The original molecule
!> \param FRAGMOL The fragment molecule
!> \param FRAGBASIS the basisinfo 
!> \param AUXBASIS logical = true if AUXBASIS is given
!> \param ATOMS List of atoms to be included in the fragment
!> \param nATOMS The number of atoms to be included
!> \param lupri Default output unit
SUBROUTINE BUILD_FRAGMENT(DALMOL,FRAGMOL,FRAGBASIS,AUXBASIS,CABSBASIS,JKBASIS,&
     & ATOMS,nATOMS,lupri)
implicit none
INTEGER,intent(IN)                    :: NATOMS,lupri
INTEGER,intent(IN)                    :: ATOMS(NATOMS)
TYPE(MOLECULEINFO),intent(IN)         :: DALMOL
TYPE(MOLECULEINFO),intent(INOUT)      :: FRAGMOL
TYPE(BASISINFO),intent(INOUT)         :: FRAGBASIS
LOGICAL,intent(in)                    :: AUXBASIS,CABSBASIS,JKBASIS 
!
INTEGER            :: I
Character(len=22)  :: FRAGMENTNAME

IF ((NATOMS.GT. 999999).OR.(ATOMS(1).GT. 999999).OR.(ATOMS(NATOMS).GT. 999999)) &
     & CALL LSQUIT('Error in BUILD_FRAGMENT -> FRAGMENTNAME',-1)
write(FRAGMENTNAME,'(A4,3I6)') 'FRAG',NATOMS,ATOMS(1),ATOMS(NATOMS)
CALL init_MoleculeInfo(FRAGMOL,natoms,FRAGMENTNAME)
FRAGMOL%charge = DALMOL%charge
DO I = 1,nAtoms
   CALL COPY_ATOM(DALMOL,ATOMS(I),FRAGMOL,I,lupri)
ENDDO
FRAGMOL%nbastREG=0
FRAGMOL%nprimbastREG=0
FRAGMOL%nbastAUX=0
FRAGMOL%nprimbastAUX=0
FRAGMOL%nbastCABS=0
FRAGMOL%nprimbastCABS=0
FRAGMOL%nbastJK=0
FRAGMOL%nprimbastJK=0
FRAGMOL%nbastVAL=0
FRAGMOL%nprimbastVAL=0
CALL DETERMINE_NBAST(FRAGMOL,FRAGBASIS%REGULAR)
IF(AUXBASIS)THEN
   CALL DETERMINE_NBAST(FRAGMOL,FRAGBASIS%AUXILIARY)
ENDIF
IF(CABSBASIS)THEN
   CALL DETERMINE_NBAST(FRAGMOL,FRAGBASIS%CABS)
ENDIF
IF(JKBASIS)THEN
   CALL DETERMINE_NBAST(FRAGMOL,FRAGBASIS%JK)
ENDIF
END SUBROUTINE BUILD_FRAGMENT

!> \brief 
!> \author
!> \date
!> \param 
SUBROUTINE buildFragmentFromFragmentIndex(FRAGMENT,MOLECULE,FragmentIndex,iFrag,lupri)
implicit none
TYPE(MOLECULEINFO) :: FRAGMENT
TYPE(MOLECULEINFO),intent(IN)  :: MOLECULE
Integer,intent(IN)             :: FragmentIndex(MOLECULE%nAtoms)
Integer,intent(IN)             :: iFrag
Integer,intent(IN)             :: lupri
!
Integer :: iAtom
Integer :: nAtoms
!
nAtoms=0
Do iAtom=1,MOLECULE%nATOMS
  IF(FragmentIndex(iAtom) .EQ. iFrag)THEN
    nAtoms=nAtoms+1
    CALL COPY_ATOM(MOLECULE,iAtom,FRAGMENT,nAtoms,lupri)
  ENDIF
ENDDO
FRAGMENT%nAtoms = nAtoms
!
END SUBROUTINE buildFragmentFromFragmentIndex

!> \brief 
!> \author
!> \date
!> \param 
SUBROUTINE DETERMINE_NBAST(MOLECULE,BASINFO,spherical,UNCONTRACTED)
implicit none
TYPE(BASISSETINFO)  :: BASINFO
TYPE(MOLECULEINFO)  :: MOLECULE
INTEGER             :: I,TOTcont,TOTprim,R,K,type,lupri,TEMP1,TEMP2,icharge
LOGICAL,OPTIONAL    :: spherical,UNCONTRACTED
!
Logical :: spher, uncont,REG,AUX,VAL,JKAUX,CABS
!
! Defaults
spher  = .true.
uncont = .false.
! Optional settings
IF (present(spherical)) spher = spherical
IF (present(UNCONTRACTED)) uncont = UNCONTRACTED
REG = .FALSE.
AUX = .FALSE.
CABS = .FALSE.
JKAUX = .FALSE.
VAL = .FALSE.
IF(BASINFO%label(1:9) .EQ. 'REGULAR  ') REG = .TRUE.
IF(BASINFO%label(1:9) .EQ. 'AUXILIARY') AUX = .TRUE.
IF(BASINFO%label(1:9) .EQ. 'CABS     ') CABS = .TRUE.
IF(BASINFO%label(1:9) .EQ. 'JKAUX    ') JKAUX = .TRUE.
IF(BASINFO%label(1:9) .EQ. 'VALENCE  ') VAL = .TRUE.

IF(.NOT.MOLECULE%pointMolecule)THEN
   TOTcont=0
   TOTprim=0
   R = BASINFO%Labelindex
   DO I=1,MOLECULE%nAtoms
      IF(R.EQ. 0)THEN
         icharge = INT(MOLECULE%ATOM(I)%charge)
         type = BASINFO%chargeindex(icharge) 
      ELSE
         type=MOLECULE%ATOM(I)%IDtype(R)
      ENDIF
      IF(.NOT.MOLECULE%ATOM(I)%Pointcharge)THEN
         IF(uncont)THEN
            TOTcont=TOTcont+BASINFO%ATOMTYPE(type)%Totnprim
            IF(REG) MOLECULE%ATOM(I)%nprimOrbREG=BASINFO%ATOMTYPE(type)%Totnprim
            IF(AUX) MOLECULE%ATOM(I)%nprimOrbAUX=BASINFO%ATOMTYPE(type)%Totnprim
            IF(CABS) MOLECULE%ATOM(I)%nprimOrbCABS=BASINFO%ATOMTYPE(type)%Totnprim
            IF(JKAUX) MOLECULE%ATOM(I)%nprimOrbJK=BASINFO%ATOMTYPE(type)%Totnprim
            IF(VAL) MOLECULE%ATOM(I)%nprimOrbVAL=BASINFO%ATOMTYPE(type)%Totnprim
            IF(REG) MOLECULE%ATOM(I)%ncontOrbREG=BASINFO%ATOMTYPE(type)%Totnprim
            IF(AUX) MOLECULE%ATOM(I)%ncontOrbAUX=BASINFO%ATOMTYPE(type)%Totnprim
            IF(CABS) MOLECULE%ATOM(I)%ncontOrbCABS=BASINFO%ATOMTYPE(type)%Totnprim
            IF(JKAUX) MOLECULE%ATOM(I)%ncontOrbJK=BASINFO%ATOMTYPE(type)%Totnprim
            IF(VAL) MOLECULE%ATOM(I)%ncontOrbVAL=BASINFO%ATOMTYPE(type)%Totnprim
            TOTprim=TOTcont
         ELSE !DEFAULT
            TOTcont=TOTcont+BASINFO%ATOMTYPE(type)%Totnorb      
            TOTprim=TOTprim+BASINFO%ATOMTYPE(type)%Totnprim      
            IF(REG) MOLECULE%ATOM(I)%nprimOrbREG=BASINFO%ATOMTYPE(type)%Totnprim      
            IF(AUX) MOLECULE%ATOM(I)%nprimOrbAUX=BASINFO%ATOMTYPE(type)%Totnprim      
            IF(CABS) MOLECULE%ATOM(I)%nprimOrbCABS=BASINFO%ATOMTYPE(type)%Totnprim
            IF(JKAUX) MOLECULE%ATOM(I)%nprimOrbJK=BASINFO%ATOMTYPE(type)%Totnprim
            IF(VAL) MOLECULE%ATOM(I)%nprimOrbVAL=BASINFO%ATOMTYPE(type)%Totnprim      
            IF(REG) MOLECULE%ATOM(I)%ncontOrbREG=BASINFO%ATOMTYPE(type)%Totnorb      
            IF(AUX) MOLECULE%ATOM(I)%ncontOrbAUX=BASINFO%ATOMTYPE(type)%Totnorb      
            IF(CABS) MOLECULE%ATOM(I)%ncontOrbCABS=BASINFO%ATOMTYPE(type)%Totnorb      
            IF(JKAUX) MOLECULE%ATOM(I)%ncontOrbJK=BASINFO%ATOMTYPE(type)%Totnorb      
            IF(VAL) MOLECULE%ATOM(I)%ncontOrbVAL=BASINFO%ATOMTYPE(type)%Totnorb      
         ENDIF
      ELSE
         IF(REG) MOLECULE%ATOM(I)%nprimOrbREG=0
         IF(AUX) MOLECULE%ATOM(I)%nprimOrbAUX=0
         IF(CABS) MOLECULE%ATOM(I)%nprimOrbCABS=0
         IF(JKAUX) MOLECULE%ATOM(I)%nprimOrbJK=0
         IF(VAL) MOLECULE%ATOM(I)%nprimOrbVAL=0
         IF(REG) MOLECULE%ATOM(I)%ncontOrbREG=0
         IF(AUX) MOLECULE%ATOM(I)%ncontOrbAUX=0
         IF(CABS) MOLECULE%ATOM(I)%ncontOrbCABS=0
         IF(JKAUX) MOLECULE%ATOM(I)%ncontOrbJK=0
         IF(VAL) MOLECULE%ATOM(I)%ncontOrbVAL=0
      ENDIF
   ENDDO
   BASINFO%nbast=TOTcont
   BASINFO%nprimbast=TOTprim
   IF(REG)MOLECULE%nbastREG=TOTcont
   IF(REG)MOLECULE%nprimbastREG=TOTprim
   
   IF(AUX)MOLECULE%nbastAUX=TOTcont
   IF(AUX)MOLECULE%nprimbastAUX=TOTprim
   
   IF(CABS)MOLECULE%nbastCABS=TOTcont
   IF(CABS)MOLECULE%nprimbastCABS=TOTprim
   
   IF(JKAUX)MOLECULE%nbastJK=TOTcont
   IF(JKAUX)MOLECULE%nprimbastJK=TOTprim
   
   IF(VAL)MOLECULE%nbastVAL=TOTcont
   IF(VAL)MOLECULE%nprimbastVAL=TOTprim
ENDIF


END SUBROUTINE DETERMINE_NBAST

SUBROUTINE GET_GEOMETRY(LUPRI,IPRINT,MOLECULE,natoms,X,Y,Z)
IMPLICIT NONE
INTEGER            :: LUPRI,IPRINT,natoms
TYPE(MOLECULEINFO) :: MOLECULE
REAL(REALK)        :: X(natoms),Y(natoms),Z(natoms)
!
integer :: I

DO I=1,nAtoms
     X(I) = MOLECULE%ATOM(I)%CENTER(1)
     Y(I) = MOLECULE%ATOM(I)%CENTER(2)
     Z(I) = MOLECULE%ATOM(I)%CENTER(3)
ENDDO

END SUBROUTINE GET_GEOMETRY

SUBROUTINE PRINT_GEOMETRY(MOLECULE,LUPRI)
IMPLICIT NONE
INTEGER :: LUPRI
INTEGER :: I
CHARACTER(len=1)   :: CHRXYZ(3)=(/'x','y','z'/)
TYPE(MOLECULEINFO) :: MOLECULE
   WRITE (LUPRI,'(2X,A,I3)')' Total number of coordinates:',3*MOLECULE%natoms
   WRITE (LUPRI,'(2X,A)')' Written in atomic units    '
   DO I=1,MOLECULE%nAtoms
      WRITE (LUPRI,'(/I4,3X,A,5X,A,3X,F15.10)')&
           &  (3*I-2), MOLECULE%ATOM(I)%Name,CHRXYZ(1),&
           & MOLECULE%ATOM(I)%CENTER(1)
      WRITE (LUPRI,'(I4,12X,A,3X,F15.10)')&
           &  3*I-1, CHRXYZ(2), MOLECULE%ATOM(I)%CENTER(2),&
           &  3*I, CHRXYZ(3), MOLECULE%ATOM(I)%CENTER(3)
   ENDDO
END SUBROUTINE PRINT_GEOMETRY 

END MODULE molecule_module