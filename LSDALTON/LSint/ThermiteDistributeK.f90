!> @file 
!> Contains integral distribution routines that places calculated integrals in the proper output
!> Thermite integral distribution module
!> \author \latexonly T. Kj{\ae}rgaard, S. Reine  \endlatexonly
!> \date 2009-02-05
MODULE thermite_distributeK
  use thermite_distribute
  use TYPEDEF
  use READMOLEFILE
  use BuildBasisSet
!  use ODbatches
  use OD_type
  use sphcart_matrices
  use precision
  use lstiming
  use thermite_integrals
  use thermite_OD
  use LSTENSOR_OPERATIONSMOD
  use OverlapType

CONTAINS
!> \brief Distribute exchange-type integrals
!> \author \latexonly S. Reine  \endlatexonly
!> \date 2011-03-08
!> \param Kmat contains the result lstensor
!> \param CDAB matrix containing calculated integrals
!> \param Dmat contains the rhs-density matrix/matrices
!> \param ndmat number of rhs-density matries
!> \param PQ information about the calculated integrals (to be distributed)
!> \param Input contain info about the requested integral 
!> \param Lsoutput contain info about the requested output, and actual output
!> \param LUPRI logical unit number for output printing
!> \param IPRINT integer containing printlevel
SUBROUTINE distributeExchange(Kmat,CDAB,Dmat,ndmat,factor,PQ,Input,Lsoutput,LUPRI,IPRINT)
implicit none 
Type(integrand),intent(in)         :: PQ
Type(IntegralInput),intent(in)     :: Input
Type(IntegralOutput),intent(inout) :: Lsoutput
Integer,intent(in)                 :: ndmat,LUPRI,IPRINT
REAL(REALK),pointer                :: CDAB(:)
TYPE(lstensor),intent(inout)       :: Kmat
TYPE(lstensor),intent(in)          :: Dmat
Real(realk),intent(IN)             :: factor
!
type(overlap),pointer :: P,Q
logical :: SamePQ,SameLHSaos,SameRHSaos,SameODs,nucleiP,nucleiQ
Logical :: permuteAB,permuteCD,permuteOD
integer :: nAngmomP,ngeoderivcomp,nPasses
integer :: iPass,iPassP,iPassQ,iDeriv,iDerivP,iDerivQ,maxAng,maxBat
integer :: nA,nB,nC,nD,batchA,batchB,batchC,batchD,atomA,atomB,atomC,atomD
integer :: indAC,indBC,indAD,indBD,nAk,nBk,nCk,nDk,sAk,sBk,sCk,sDk
integer :: indCA,indCB,indDA,indDB,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd
integer :: ndim5,nderiv,ider,iatom,ndim5output,idim5
Real(realk),pointer :: kAC(:),kBC(:),kAD(:),kBD(:),dBD(:),dAD(:),dBC(:),dAC(:)
Real(realk),pointer :: kCA(:),kCB(:),kDA(:),kDB(:),dDB(:),dDA(:),dCB(:),dCA(:)
real(realk) :: symfactor
real(realk),parameter :: D2=2E0_realk 
logical :: DRHS_SYM,antiAB,AntipermuteAB
Type(derivativeInfo) :: derivInfo

antiAB=.FALSE.
DRHS_SYM = Input%DRHS_SYM
IF(DRHS_SYM)THEN
   symfactor = D2 * factor
ELSE
   symfactor = factor
ENDIF
P => PQ%P%p
Q => PQ%Q%p
nAngmomP       = P%nAngmom
SamePQ         = PQ%samePQ
SameLHSaos     = INPUT%SameLHSaos
SameRHSaos     = INPUT%SameRHSaos
SameODs        = INPUT%SameODs
ngeoderivcomp  = Input%ngeoderivcomp
nderiv         = Input%ngeoderivcomp
ndim5         = nDeriv
ndim5output   = Lsoutput%ndim(5)/ndmat
IF(P%magderiv.EQ.1)THEN
   ndim5=ndim5*3
   antiAB=.TRUE.
ENDIF
IF(nderiv.GT.1)then
   CALL initDerivativeOverlapInfo(derivInfo,PQ,Input)
   IF (IPRINT.GT. 50) THEN
      CALL printDerivativeOverlapInfo(derivInfo,6)
   ENDIF
endif
nucleiP        = (P%orbital1%type_nucleus.AND.P%orbital2%type_empty).OR. &
     &           (P%orbital1%type_empty.AND.P%orbital2%type_nucleus)
nucleiQ        = (Q%orbital1%type_nucleus.AND.Q%orbital2%type_empty).OR. &
     &           (Q%orbital1%type_empty.AND.Q%orbital2%type_nucleus)

nPasses = P%nPasses*Q%nPasses
iPass = 0
DO iPassP=1,P%nPasses
  atomA  = P%orb1atom(iPassP)
  batchA = P%orb1batch(iPassP)
  nA     = P%orbital1%totOrbitals
  atomB  = P%orb2atom(iPassP)
  batchB = P%orb2batch(iPassP)
  IF(nderiv.GT.1)then
     derivInfo%Atom(1)=atomA
     derivInfo%Atom(2)=atomB
  ENDIF
  nB     = P%orbital2%totOrbitals
  IF (nucleiP) THEN
    atomA = 1
    atomB = 1
  ENDIF
  permuteAB  = SameLHSaos.AND.((batchA.NE.batchB).OR.(atomA.NE.atomB))
  AntipermuteAB  = permuteAB.AND.antiAB
  DO iPassQ=1,Q%nPasses
    iPass = iPass + 1

    atomC  = Q%orb1atom(iPassQ)
    batchC = Q%orb1batch(iPassQ)
    nC     = Q%orbital1%totOrbitals
    atomD  = Q%orb2atom(iPassQ)
    batchD = Q%orb2batch(iPassQ)
    nD     = Q%orbital2%totOrbitals
    IF(nderiv.GT.1)then
       derivInfo%Atom(3)=atomC
       derivInfo%Atom(4)=atomD
    ENDIF
    IF (nucleiQ) THEN
      atomC = 1
      atomD = 1
    ENDIF
    permuteCD = SameRHSaos.AND.((batchC.NE.batchD).OR.(atomC.NE.atomD))
!    permuteOD = SameODs.AND.( ((batchA.NE.batchC).OR.(atomA.NE.atomC)).OR.&
!   &                          ((batchB.NE.batchD).OR.(atomB.NE.atomD)) )
    permuteOD = SameODs.AND..NOT.((batchA.EQ.batchC).AND.(atomA.EQ.atomC).AND.&
   &                          (batchB.EQ.batchD).AND.(atomB.EQ.atomD) )

    IF (permuteOD.AND.permuteCD.AND.permuteAB) THEN
       IF(DRHS_SYM)THEN
          !Exchange mat pointers
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          indCB  =  Kmat%index(atomC,atomB,1,1)
          kCB => Kmat%LSAO(indCB)%elms
          indDA  =  Kmat%index(atomD,atomA,1,1)
          kDA => Kmat%LSAO(indDA)%elms
          indDB  =  Kmat%index(atomD,atomB,1,1)
          kDB => Kmat%LSAO(indDB)%elms
          !Exchange dim and start
          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nBk = Kmat%LSAO(indDB)%nLocal(2)
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          nDk = Kmat%LSAO(indDB)%nLocal(1)
          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1 
          maxBat = Kmat%LSAO(indDB)%maxBat
          maxAng = Kmat%LSAO(indDB)%maxAng
          sDK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
          sBK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxANg*maxBat)-1
          !Densities mat pointers
          indCA  =  Dmat%index(atomC,atomA,1,1)
          dCA => Dmat%LSAO(indCA)%elms
          indCB  =  Dmat%index(atomC,atomB,1,1)
          dCB => Dmat%LSAO(indCB)%elms
          indDA  =  Dmat%index(atomD,atomA,1,1)
          dDA => Dmat%LSAO(indDA)%elms
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          !Densities dim and start
          nAd = Dmat%LSAO(indCA)%nLocal(2)
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nCd = Dmat%LSAO(indCA)%nLocal(1)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indCA)%maxBat
          maxAng = Dmat%LSAO(indCA)%maxAng
          sAd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
          sCd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1

          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       ELSE
          indAC  =  Kmat%index(atomA,atomC,1,1)
          KAC => Kmat%LSAO(indAC)%elms
          indBC  =  Kmat%index(atomB,atomC,1,1)
          KBC => Kmat%LSAO(indBC)%elms
          indAD  =  Kmat%index(atomA,atomD,1,1)
          KAD => Kmat%LSAO(indAD)%elms
          indBD  =  Kmat%index(atomB,atomD,1,1)
          KBD => Kmat%LSAO(indBD)%elms
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          indCB  =  Kmat%index(atomC,atomB,1,1)
          kCB => Kmat%LSAO(indCB)%elms
          indDA  =  Kmat%index(atomD,atomA,1,1)
          kDA => Kmat%LSAO(indDA)%elms
          indDB  =  Kmat%index(atomD,atomB,1,1)
          kDB => Kmat%LSAO(indDB)%elms

          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nBk = Kmat%LSAO(indDB)%nLocal(2)
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          nDk = Kmat%LSAO(indDB)%nLocal(1)

          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 

          maxBat = Kmat%LSAO(indDB)%maxBat
          maxAng = Kmat%LSAO(indDB)%maxAng
          sDK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
          sBK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1

          !Densities
          indAC  =  Dmat%index(atomA,atomC,1,1)
          dAC => Dmat%LSAO(indAC)%elms
          indBC  =  Dmat%index(atomB,atomC,1,1)
          dBC => Dmat%LSAO(indBC)%elms
          indAD  =  Dmat%index(atomA,atomD,1,1)
          dAD => Dmat%LSAO(indAD)%elms
          indBD  =  Dmat%index(atomB,atomD,1,1)
          dBD => Dmat%LSAO(indBD)%elms
          indCA  =  Dmat%index(atomC,atomA,1,1)
          dCA => Dmat%LSAO(indCA)%elms
          indCB  =  Dmat%index(atomC,atomB,1,1)
          dCB => Dmat%LSAO(indCB)%elms
          indDA  =  Dmat%index(atomD,atomA,1,1)
          dDA => Dmat%LSAO(indDA)%elms
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          
          nAd = Dmat%LSAO(indCA)%nLocal(2)
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nCd = Dmat%LSAO(indCA)%nLocal(1)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indCA)%maxBat
          maxAng = Dmat%LSAO(indCA)%maxAng
          sAd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
          sCd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 

       ENDIF
    ELSE IF (permuteOD.AND.permuteCD) THEN
       indAC  =  Kmat%index(atomA,atomC,1,1)
       KAC => Kmat%LSAO(indAC)%elms
       indCA  =  Kmat%index(atomC,atomA,1,1)
       kCA => Kmat%LSAO(indCA)%elms
       indAD  =  Kmat%index(atomA,atomD,1,1)
       KAD => Kmat%LSAO(indAD)%elms
       indDA  =  Kmat%index(atomD,atomA,1,1)
       kDA => Kmat%LSAO(indDA)%elms
       !Exchange dim and start
       nAk = Kmat%LSAO(indCA)%nLocal(2) 
       nCk = Kmat%LSAO(indCA)%nLocal(1)
       nDk = Kmat%LSAO(indDA)%nLocal(1)
       maxBat = Kmat%LSAO(indCA)%maxBat
       maxAng = Kmat%LSAO(indCA)%maxAng
       sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
       sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
       maxAng = Kmat%LSAO(indDA)%maxAng
       sDK = Kmat%LSAO(indDA)%startLocalOrb(1+(batchD-1)*maxAng) - 1 

       indBD  =  Dmat%index(atomB,atomD,1,1)
       dBD => Dmat%LSAO(indBD)%elms
       indDB  =  Dmat%index(atomD,atomB,1,1)
       dDB => Dmat%LSAO(indDB)%elms
       indBC  =  Dmat%index(atomB,atomC,1,1)
       dBC => Dmat%LSAO(indBC)%elms
       indCB  =  Dmat%index(atomC,atomB,1,1)
       dCB => Dmat%LSAO(indCB)%elms

       nBd = Dmat%LSAO(indDB)%nLocal(2)
       nCd = Dmat%LSAO(indCB)%nLocal(1)
       nDd = Dmat%LSAO(indDB)%nLocal(1)
       maxBat = Dmat%LSAO(indDB)%maxBat
       maxAng = Dmat%LSAO(indDB)%maxAng
       sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
       sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       maxAng = Dmat%LSAO(indCB)%maxAng
       sCd = Dmat%LSAO(indCB)%startLocalOrb(1+(batchC-1)*maxAng) - 1
       
    ELSE IF (permuteOD.AND.permuteAB) THEN
       indAC  =  Kmat%index(atomA,atomC,1,1)
       KAC => Kmat%LSAO(indAC)%elms
       indCA  =  Kmat%index(atomC,atomA,1,1)
       kCA => Kmat%LSAO(indCA)%elms
       indBC  =  Kmat%index(atomB,atomC,1,1)
       KBC => Kmat%LSAO(indBC)%elms
       indCB  =  Kmat%index(atomC,atomB,1,1)
       kCB => Kmat%LSAO(indCB)%elms

       nAk = Kmat%LSAO(indCA)%nLocal(2) 
       nBk = Kmat%LSAO(indCB)%nLocal(2)
       nCk = Kmat%LSAO(indCA)%nLocal(1)

       maxBat = Kmat%LSAO(indCA)%maxBat
       maxAng = Kmat%LSAO(indCA)%maxAng
       sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
       sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
       maxBat = Kmat%LSAO(indCB)%maxBat
       maxAng = Kmat%LSAO(indCB)%maxAng
       sBK = Kmat%LSAO(indCB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
       indBD  =  Dmat%index(atomB,atomD,1,1)
       dBD => Dmat%LSAO(indBD)%elms
       indDB  =  Dmat%index(atomD,atomB,1,1)
       dDB => Dmat%LSAO(indDB)%elms
       indAD  =  Dmat%index(atomA,atomD,1,1)
       dAD => Dmat%LSAO(indAD)%elms
       indDA  =  Dmat%index(atomD,atomA,1,1)
       dDA => Dmat%LSAO(indDA)%elms

       nAd = Dmat%LSAO(indDA)%nLocal(2)
       nBd = Dmat%LSAO(indDB)%nLocal(2)
       nDd = Dmat%LSAO(indDB)%nLocal(1)
       maxBat = Dmat%LSAO(indDA)%maxBat
       maxAng = Dmat%LSAO(indDA)%maxAng
       sAd = Dmat%LSAO(indDA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
       maxBat = Dmat%LSAO(indDB)%maxBat
       maxAng = Dmat%LSAO(indDB)%maxAng
       sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
       sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 

    ELSE IF (permuteAB.AND.permuteCD) THEN
       IF(DRHS_SYM)THEN
          !Exchange mat pointers
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          indCB  =  Kmat%index(atomC,atomB,1,1)
          kCB => Kmat%LSAO(indCB)%elms
          indDA  =  Kmat%index(atomD,atomA,1,1)
          kDA => Kmat%LSAO(indDA)%elms
          indDB  =  Kmat%index(atomD,atomB,1,1)
          kDB => Kmat%LSAO(indDB)%elms
          !Exchange dim and start
          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nBk = Kmat%LSAO(indDB)%nLocal(2)
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          nDk = Kmat%LSAO(indDB)%nLocal(1)
          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1 
          maxBat = Kmat%LSAO(indDB)%maxBat
          maxAng = Kmat%LSAO(indDB)%maxAng
          sDK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
          sBK = Kmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxANg*maxBat)-1
          !Densities mat pointers
          indCA  =  Dmat%index(atomC,atomA,1,1)
          dCA => Dmat%LSAO(indCA)%elms
          indCB  =  Dmat%index(atomC,atomB,1,1)
          dCB => Dmat%LSAO(indCB)%elms
          indDA  =  Dmat%index(atomD,atomA,1,1)
          dDA => Dmat%LSAO(indDA)%elms
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          !Densities dim and start
          nAd = Dmat%LSAO(indCA)%nLocal(2)
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nCd = Dmat%LSAO(indCA)%nLocal(1)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indCA)%maxBat
          maxAng = Dmat%LSAO(indCA)%maxAng
          sAd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
          sCd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1

          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       ELSE
          indAC  =  Kmat%index(atomA,atomC,1,1)
          KAC => Kmat%LSAO(indAC)%elms
          indBC  =  Kmat%index(atomB,atomC,1,1)
          KBC => Kmat%LSAO(indBC)%elms
          indBD  =  Kmat%index(atomB,atomD,1,1)
          KBD => Kmat%LSAO(indBD)%elms
          indAD  =  Kmat%index(atomA,atomD,1,1)
          KAD => Kmat%LSAO(indAD)%elms
          
          nAk = Kmat%LSAO(indAC)%nLocal(1) 
          nBk = Kmat%LSAO(indBD)%nLocal(1)
          nCk = Kmat%LSAO(indAC)%nLocal(2)
          nDk = Kmat%LSAO(indBD)%nLocal(2)
          maxBat = Kmat%LSAO(indAC)%maxBat
          maxAng = Kmat%LSAO(indAC)%maxAng
          sAK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          sCK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1
          maxBat = Kmat%LSAO(indBD)%maxBat
          maxAng = Kmat%LSAO(indBD)%maxAng
          sBK = Kmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          sDK = Kmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1 

          indBD  =  Dmat%index(atomB,atomD,1,1)
          dBD => Dmat%LSAO(indBD)%elms
          indAD  =  Dmat%index(atomA,atomD,1,1)
          dAD => Dmat%LSAO(indAD)%elms
          indAC  =  Dmat%index(atomA,atomC,1,1)
          dAC => Dmat%LSAO(indAC)%elms
          indBC  =  Dmat%index(atomB,atomC,1,1)
          dBC => Dmat%LSAO(indBC)%elms
          
          nAd = Dmat%LSAO(indAC)%nLocal(1)
          nBd = Dmat%LSAO(indBD)%nLocal(1)
          nCd = Dmat%LSAO(indAC)%nLocal(2)
          nDd = Dmat%LSAO(indBD)%nLocal(2)
          maxBat = Dmat%LSAO(indAC)%maxBat
          maxAng = Dmat%LSAO(indAC)%maxAng
          sAd = Dmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          sCd = Dmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat)-1
          maxBat = Dmat%LSAO(indBD)%maxBat
          maxAng = Dmat%LSAO(indBD)%maxAng
          sBd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          sDd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat)-1 
       ENDIF
    ELSE IF (permuteAB) THEN
       IF(DRHS_SYM)THEN
          !Exchange mat pointers
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          indCB  =  Kmat%index(atomC,atomB,1,1)
          kCB => Kmat%LSAO(indCB)%elms
          !Exchange dim and start
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nBk = Kmat%LSAO(indCB)%nLocal(2)
          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1 
          maxBat = Kmat%LSAO(indCB)%maxBat
          maxAng = Kmat%LSAO(indCB)%maxAng
          sBK = Kmat%LSAO(indCB)%startLocalOrb(1+(batchB-1)*maxAng+maxANg*maxBat)-1
          !Densities mat pointers
          indDA  =  Dmat%index(atomD,atomA,1,1)
          dDA => Dmat%LSAO(indDA)%elms
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          !Densities dim and start
          nAd = Dmat%LSAO(indCA)%nLocal(2)
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indCA)%maxBat
          maxAng = Dmat%LSAO(indCA)%maxAng
          sAd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat) - 1 
          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       ELSE
          indAC  =  Kmat%index(atomA,atomC,1,1)
          KAC => Kmat%LSAO(indAC)%elms
          indBC  =  Kmat%index(atomB,atomC,1,1)
          KBC => Kmat%LSAO(indBC)%elms
          
          nAk = Kmat%LSAO(indAC)%nLocal(1) 
          nBk = Kmat%LSAO(indBC)%nLocal(1)
          nCk = Kmat%LSAO(indAC)%nLocal(2)
          maxBat = Kmat%LSAO(indAC)%maxBat
          maxAng = Kmat%LSAO(indAC)%maxAng
          sAK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          sCK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1
          maxBat = Kmat%LSAO(indBC)%maxBat
          maxAng = Kmat%LSAO(indBC)%maxAng
          sBK = Kmat%LSAO(indBC)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          
          indBD  =  Dmat%index(atomB,atomD,1,1)
          dBD => Dmat%LSAO(indBD)%elms
          indAD  =  Dmat%index(atomA,atomD,1,1)
          dAD => Dmat%LSAO(indAD)%elms
          
          nAd = Dmat%LSAO(indAD)%nLocal(1)
          nBd = Dmat%LSAO(indBD)%nLocal(1)
          nDd = Dmat%LSAO(indBD)%nLocal(2)
          maxBat = Dmat%LSAO(indAD)%maxBat
          maxAng = Dmat%LSAO(indAD)%maxAng
          sAd = Dmat%LSAO(indAD)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          maxBat = Dmat%LSAO(indBD)%maxBat
          maxAng = Dmat%LSAO(indBD)%maxAng
          sBd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          sDd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1 
       ENDIF
    ELSE IF (permuteCD) THEN
       IF(DRHS_SYM)THEN
          !Exchange mat pointers
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          indDA  =  Kmat%index(atomD,atomA,1,1)
          kDA => Kmat%LSAO(indDA)%elms
          !Exchange dim and start
          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          nDk = Kmat%LSAO(indDA)%nLocal(1)
          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1 
          maxBat = Kmat%LSAO(indDA)%maxBat
          maxAng = Kmat%LSAO(indDA)%maxAng
          sDK = Kmat%LSAO(indDA)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
          !Densities mat pointers
          indCB  =  Dmat%index(atomC,atomB,1,1)
          dCB => Dmat%LSAO(indCB)%elms
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          !Densities dim and start
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nCd = Dmat%LSAO(indCA)%nLocal(1)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indCA)%maxBat
          maxAng = Dmat%LSAO(indCA)%maxAng
          sCd = Dmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       ELSE
          indAC  =  Kmat%index(atomA,atomC,1,1)
          KAC => Kmat%LSAO(indAC)%elms
          indAD  =  Kmat%index(atomA,atomD,1,1)
          KAD => Kmat%LSAO(indAD)%elms
          
          nAk = Kmat%LSAO(indAC)%nLocal(1) 
          nCk = Kmat%LSAO(indAC)%nLocal(2)
          nDk = Kmat%LSAO(indAD)%nLocal(2)
          
          maxBat = Kmat%LSAO(indAC)%maxBat
          maxAng = Kmat%LSAO(indAC)%maxAng
          sAK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          sCK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1
          maxBat = Kmat%LSAO(indAD)%maxBat
          maxAng = Kmat%LSAO(indAD)%maxAng
          sDK = Kmat%LSAO(indAD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1
          
          indBD  =  Dmat%index(atomB,atomD,1,1)
          dBD => Dmat%LSAO(indBD)%elms
          indBC  =  Dmat%index(atomB,atomC,1,1)
          dBC => Dmat%LSAO(indBC)%elms
          
          nBd = Dmat%LSAO(indBD)%nLocal(1)
          nCd = Dmat%LSAO(indBC)%nLocal(2)
          nDd = Dmat%LSAO(indBD)%nLocal(2)
          maxBat = Dmat%LSAO(indBD)%maxBat
          maxAng = Dmat%LSAO(indBD)%maxAng
          sBd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          sDd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1 
          maxBat = Dmat%LSAO(indBC)%maxBat
          maxAng = Dmat%LSAO(indBC)%maxAng
          sCd = Dmat%LSAO(indBC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1 
       ENDIF
    ELSE IF (permuteOD) THEN
       indAC  =  Kmat%index(atomA,atomC,1,1)
       KAC => Kmat%LSAO(indAC)%elms
       indCA  =  Kmat%index(atomC,atomA,1,1)
       kCA => Kmat%LSAO(indCA)%elms
          
       nAk = Kmat%LSAO(indAC)%nLocal(1) 
       nCk = Kmat%LSAO(indAC)%nLocal(2)
       maxBat = Kmat%LSAO(indAC)%maxBat
       maxAng = Kmat%LSAO(indAC)%maxAng
       sAK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
       sCK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1

       indBD  =  Dmat%index(atomB,atomD,1,1)
       dBD => Dmat%LSAO(indBD)%elms
       indDB  =  Dmat%index(atomD,atomB,1,1)
       dDB => Dmat%LSAO(indDB)%elms
       
       nBd = Dmat%LSAO(indBD)%nLocal(1)
       nDd = Dmat%LSAO(indBD)%nLocal(2)
       maxBat = Dmat%LSAO(indBD)%maxBat
       maxAng = Dmat%LSAO(indBD)%maxAng
       sBd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
       sDd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1 
    ELSE
       IF(DRHS_SYM)THEN
          !Exchange mat pointers
          indCA  =  Kmat%index(atomC,atomA,1,1)
          kCA => Kmat%LSAO(indCA)%elms
          !Exchange dim and start
          nAk = Kmat%LSAO(indCA)%nLocal(2) 
          nCk = Kmat%LSAO(indCA)%nLocal(1)
          maxBat = Kmat%LSAO(indCA)%maxBat
          maxAng = Kmat%LSAO(indCA)%maxAng
          sCK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchC-1)*maxAng) - 1
          sAK = Kmat%LSAO(indCA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1 
          !Densities mat pointers
          indDB  =  Dmat%index(atomD,atomB,1,1)
          dDB => Dmat%LSAO(indDB)%elms
          !Densities dim and start
          nBd = Dmat%LSAO(indDB)%nLocal(2)
          nDd = Dmat%LSAO(indDB)%nLocal(1)
          maxBat = Dmat%LSAO(indDB)%maxBat
          maxAng = Dmat%LSAO(indDB)%maxAng
          sBd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat) - 1
          sDd = Dmat%LSAO(indDB)%startLocalOrb(1+(batchD-1)*maxAng) - 1 
       ELSE
          indAC  =  Kmat%index(atomA,atomC,1,1)
          KAC => Kmat%LSAO(indAC)%elms
          
          nAk = Kmat%LSAO(indAC)%nLocal(1) 
          nCk = Kmat%LSAO(indAC)%nLocal(2)
          maxBat = Kmat%LSAO(indAC)%maxBat
          maxAng = Kmat%LSAO(indAC)%maxAng
          sAK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchA-1)*maxAng) - 1 
          sCK = Kmat%LSAO(indAC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat) - 1
          
          indBD  =  Dmat%index(atomB,atomD,1,1)
          dBD => Dmat%LSAO(indBD)%elms
          
          nBd = Dmat%LSAO(indBD)%nLocal(1)
          nDd = Dmat%LSAO(indBD)%nLocal(2)
          maxBat = Dmat%LSAO(indBD)%maxBat
          maxAng = Dmat%LSAO(indBD)%maxAng
          sBd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchB-1)*maxAng) - 1
          sDd = Dmat%LSAO(indBD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat) - 1 
       ENDIF
    ENDIF
    DO iDeriv=1,ndim5
      iDim5 = iDeriv
      IF (nderiv.GT. 1)THEN
         iDer = derivInfo%dirComp(iDeriv)
         iAtom = derivInfo%Atom(derivInfo%AO(1,iDeriv))
         iDim5 = 3*(iAtom-1)+ider
      ENDIF
      IF (permuteOD.AND.permuteCD.AND.permuteAB) THEN
         IF(DRHS_sym)THEN
            IF(ndmat.EQ.1)THEN
               CALL Kfullsym_ndmat1(kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
                    & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
                    & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri)
            ELSE
               CALL Kfullsym(kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
                    & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
                    & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            ENDIF
         ELSE
            CALL Kfull(kAC,dBD,KAD,DBC,KBC,DAD,kBD,dAC,kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
                 & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteOD.AND.permuteCD) THEN
         IF(DRHS_sym)THEN
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAD_BC(kAD,dBC,&
!                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)

            CALL kCA_DB_kDA_CB(kCA,dDB,kDA,dCB,&
                 & nAk,nCk,nDk,sAk,sCk,sDK,nBd,nCd,nDd,sBd,sCd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)

!            CALL kCA_DB(kCA,dDB,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kDA_CB(kDA,dCB,&
!                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kAD_BC(kAD,dBC,&
                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kDA_CB(kDA,dCB,&
                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteOD.AND.permuteAB) THEN
         IF(DRHS_sym)THEN
            CALL KCA_DB_kCB_DA(kCA,dDB,kCB,dDA,&
                 & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kCA_DB(kCA,dDB,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kCB_DA(kCB,dDA,&
!                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kBC_AD(kBC,dAD,&
!                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBC_AD(kBC,dAD,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCB_DA(kCB,dDA,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (AntipermuteAB.AND.permuteCD) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCB_DA(kCB,dDA,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            call kDB_CA(kDB,dCA,&
                 & nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd,&
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            call kDA_CB(kDA,dCB,&
                 & nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd,&
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kBC_AD(kBC,dAD,&
!                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kBD_AC(kBD,dAC,&
!                 & nBk,nDk,sBK,sDK,nAd,nCd,sAd,sCd, &
!                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAD_BC(kAD,dBC,&
!                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBC_AD(kBC,dAD,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBD_AC(kBD,dAC,&
                 & nBk,nDk,sBK,sDK,nAd,nCd,sAd,sCd, &
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kAD_BC(kAD,dBC,&
                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteAB.AND.permuteCD) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCB_DA(kCB,dDA,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            call kDB_CA(kDB,dCA,&
                 & nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd,&
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            call kDA_CB(kDA,dCB,&
                 & nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd,&
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!         CALL kAC_BD(kAC,dBD,&
!              & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!              & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!         CALL kBC_AD(kBC,dAD,&
!              & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!              & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!         CALL kBD_AC(kBD,dAC,&
!              & nBk,nDk,sBK,sDK,nAd,nCd,sAd,sCd, &
!              & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!         CALL kAD_BC(kAD,dBC,&
!              & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
!              & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBC_AD(kBC,dAD,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBD_AC(kBD,dAC,&
                 & nBk,nDk,sBK,sDK,nAd,nCd,sAd,sCd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kAD_BC(kAD,dBC,&
                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (AntipermuteAB) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCB_DA(kCB,dDA,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kBC_AD(kBC,dAD,&
!                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBC_AD(kBC,dAD,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,-factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteAB) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCB_DA(kCB,dDA,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kBC_AD(kBC,dAD,&
!                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kBC_AD(kBC,dAD,&
                 & nBk,nCk,sBK,sCk,nAd,nDd,sAd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteCD) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            call kDA_CB(kDA,dCB,&
                 & nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd,&
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAD_BC(kAD,dBC,&
!                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kAD_BC(kAD,dBC,&
                 & nAk,nDk,sAk,sDK,nBd,nCd,sBd,sCd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE IF (permuteOD) THEN
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!         CALL kAC_BD(kAC,dBD,&
!              & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!              & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,symfactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ELSE
         IF(DRHS_sym)THEN
            CALL kCA_DB(kCA,dDB,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
!            CALL kAC_BD(kAC,dBD,&
!                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
!                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ELSE
            CALL kAC_BD(kAC,dBD,&
                 & nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd, &
                 & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
         ENDIF
      ENDIF
    ENDDO !iDeriv
  ENDDO !iPassQ
ENDDO !iPassP
IF (nderiv.GT. 1) CALL freeDerivativeOverlapInfo(derivInfo)

CONTAINS
SUBROUTINE Kfullsym_ndmat1(kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
     & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
     & CDAB,infactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri)
implicit none
Integer,intent(IN)        :: nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output),kDA(nDk,nAk,ndim5output)
Real(realk),intent(INOUT) :: kCB(nCk,nBk,ndim5output),kDB(nDk,nBk,ndim5output)
Real(realk),intent(IN)    :: dDB(nDd,nBd),dCB(nCd,nBd),dDA(nDd,nAd),dCA(nCd,nAd)
Real(realk),intent(IN)    :: infactor
!
Integer :: iA,iB,iC,iD
real(realk) :: kBDtmp,kADtmp,kDBtmp,kDAtmp,dBDtmp,dADtmp,dDBtmp,dDAtmp,int,factor
real(realk),parameter :: D0=0E0_realk,D2=2E0_realk
!
!$OMP CRITICAL (distributeFockBlock)
factor = D2*infactor
DO iB=1,nB
 DO iA=1,nA
  DO iD=1,nD
    kDBtmp = D0
    kDAtmp = D0
    dDBtmp = factor * dDB(sDd+iD,sBd+iB)
    dDAtmp = factor * dDA(sDd+iD,sAd+iA)
    DO iC=1,nC
     int = CDAB(iC,iD,iA,iB,iDeriv,iPass)
     kCA(sCk+iC,sAk+iA,iDim5) = kCA(sCk+iC,sAk+iA,iDim5) + int * dDBtmp
     kCB(sCk+iC,sBk+iB,iDim5) = kCB(sCk+iC,sBk+iB,iDim5) + int * dDAtmp
     kDBtmp = kDBtmp + int * dCA(sCd+iC,sAd+iA)
     kDAtmp = kDAtmp + int * dCB(sCd+iC,sBd+iB)
    ENDDO
    kDB(sDk+iD,sBk+iB,iDim5) = kDB(sDk+iD,sBk+iB,iDim5) + factor * kDBtmp
    kDA(sDk+iD,sAk+iA,iDim5) = kDA(sDk+iD,sAk+iA,iDim5) + factor * kDAtmp
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE Kfullsym_ndmat1

SUBROUTINE Kfullsym(kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
     & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
     & CDAB,infactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output,ndmat),kDA(nDk,nAk,ndim5output,ndmat)
Real(realk),intent(INOUT) :: kCB(nCk,nBk,ndim5output,ndmat),kDB(nDk,nBk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dDB(nDd,nBd,ndmat),dCB(nCd,nBd,ndmat),dDA(nDd,nAd,ndmat),dCA(nCd,nAd,ndmat)
Real(realk),intent(IN)    :: infactor
!
Real(realk) :: kCATMPMAT(nC,nA,ndmat),kDATMPMAT(nD,nA,ndmat)
Real(realk) :: kCBTMPMAT(nC,nB,ndmat),kDBTMPMAT(nD,nB,ndmat)
Integer :: iA,iB,iC,iD,idmat
real(realk) :: kBDtmp,kADtmp,kDBtmp,kDAtmp,dBDtmp,dADtmp,dDBtmp,dDAtmp,int,factor
real(realk),parameter :: D0=0E0_realk,D2=2E0_realk
!
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCATMPMAT(iC,iA,idmat) = 0.0E0_realk
  ENDDO
  DO iD=1,nD
   kDATMPMAT(iD,iA,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
 DO iB=1,nB
  DO iC=1,nC
   kCBTMPMAT(iC,iB,idmat) = 0.0E0_realk
  ENDDO
  DO iD=1,nD
   kDBTMPMAT(iD,iB,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
ENDDO
factor = D2*infactor
DO iB=1,nB
 DO iA=1,nA
  DO iD=1,nD
   DO idmat=1,ndmat
    kDBtmp = D0
    kDAtmp = D0
    dDBtmp = dDB(sDd+iD,sBd+iB,idmat)
    dDAtmp = dDA(sDd+iD,sAd+iA,idmat)
    DO iC=1,nC
     kCATMPMAT(iC,iA,idmat) = kCATMPMAT(iC,iA,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dDBtmp
     kCBTMPMAT(iC,iB,idmat) = kCBTMPMAT(iC,iB,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dDAtmp
     kDBtmp = kDBtmp + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dCA(sCd+iC,sAd+iA,idmat)
     kDAtmp = kDAtmp + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dCB(sCd+iC,sBd+iB,idmat)
    ENDDO
    kDBTMPMAT(iD,iB,idmat) = kDBTMPMAT(iD,iB,idmat) + kDBtmp
    kDATMPMAT(iD,iA,idmat) = kDATMPMAT(iD,iA,idmat) + kDAtmp
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCA(sCk+iC,sAk+iA,iDim5,idmat) = kCA(sCk+iC,sAk+iA,iDim5,idmat) + factor * kCATMPMAT(iC,iA,idmat)
  ENDDO
  DO iD=1,nD
   kDA(sDk+iD,sAk+iA,iDim5,idmat) = kDA(sDk+iD,sAk+iA,iDim5,idmat) + factor * kDATMPMAT(iD,iA,idmat)
  ENDDO
 ENDDO
 DO iB=1,nB
  DO iC=1,nC
   kCB(sCk+iC,sBk+iB,iDim5,idmat) = kCB(sCk+iC,sBk+iB,iDim5,idmat) + factor * kCBTMPMAT(iC,iB,idmat)
  ENDDO
  DO iD=1,nD
   kDB(sDk+iD,sBk+iB,iDim5,idmat) = kDB(sDk+iD,sBk+iB,iDim5,idmat) + factor * kDBTMPMAT(iD,iB,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE Kfullsym

SUBROUTINE kCA_DB_kCB_DA(kCA,dDB,kCB,dDA,&
     & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
     & CDAB,infactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output,ndmat),kCB(nCk,nBk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dDB(nDd,nBd,ndmat),dDA(nDd,nAd,ndmat)
Real(realk),intent(IN)    :: infactor
!
Real(realk) :: kCATMPMAT(nC,nA,ndmat),kCBTMPMAT(nC,nB,ndmat)
Integer :: iA,iB,iC,iD,idmat
real(realk) :: kBDtmp,kADtmp,kDBtmp,kDAtmp,dBDtmp,dADtmp,dDBtmp,dDAtmp,int,factor
real(realk),parameter :: D0=0E0_realk,D2=2E0_realk
!
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCATMPMAT(iC,iA,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
 DO iB=1,nB
  DO iC=1,nC
   kCBTMPMAT(iC,iB,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
ENDDO
factor = D2*infactor
DO iB=1,nB
 DO iA=1,nA
  DO iD=1,nD
   DO idmat=1,ndmat
    dDBtmp = dDB(sDd+iD,sBd+iB,idmat)
    dDAtmp = dDA(sDd+iD,sAd+iA,idmat)
    DO iC=1,nC
     kCATMPMAT(iC,iA,idmat) = kCATMPMAT(iC,iA,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dDBtmp
     kCBTMPMAT(iC,iB,idmat) = kCBTMPMAT(iC,iB,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dDAtmp
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCA(sCk+iC,sAk+iA,iDim5,idmat) = kCA(sCk+iC,sAk+iA,iDim5,idmat) + factor * kCATMPMAT(iC,iA,idmat)
  ENDDO
 ENDDO
 DO iB=1,nB
  DO iC=1,nC
   kCB(sCk+iC,sBk+iB,iDim5,idmat) = kCB(sCk+iC,sBk+iB,iDim5,idmat) + factor * kCBTMPMAT(iC,iB,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE kCA_DB_kCB_DA

SUBROUTINE kCA_DB_kDA_CB(kCA,dDB,kDA,dCB,&
     & nAk,nCk,nDk,sAk,sCk,sDK,nBd,nCd,nDd,sBd,sCd,sDd, &
     & CDAB,infactor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nAk,nCk,nDk,sAk,sCk,sDK,nBd,nCd,nDd,sBd,sCd,sDd
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output,ndmat),kDA(nDk,nAk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dDB(nDd,nBd,ndmat),dCB(nCd,nBd,ndmat)
Real(realk),intent(IN)    :: infactor
!
Real(realk) :: kCATMPMAT(nC,nA,ndmat),kDATMPMAT(nD,nA,ndmat)
Integer :: iA,iB,iC,iD,idmat
real(realk) :: kBDtmp,kADtmp,kDBtmp,kDAtmp,dBDtmp,dADtmp,dDBtmp,dDAtmp,int,factor
real(realk),parameter :: D0=0E0_realk,D2=2E0_realk
!
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCATMPMAT(iC,iA,idmat) = 0.0E0_realk
  ENDDO
  DO iD=1,nD
   kDATMPMAT(iD,iA,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
ENDDO
factor = D2*infactor
DO iB=1,nB
 DO iD=1,nD
  DO idmat=1,ndmat
   dDBtmp = dDB(sDd+iD,sBd+iB,idmat)
   DO iA=1,nA
    kDAtmp = D0
    DO iC=1,nC
     kCATMPMAT(iC,iA,idmat) = kCATMPMAT(iC,iA,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dDBtmp
     kDAtmp = kDAtmp + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dCB(sCd+iC,sBd+iB,idmat)
    ENDDO
    kDATMPMAT(iD,iA,idmat) = kDATMPMAT(iD,iA,idmat) + kDAtmp
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCA(sCk+iC,sAk+iA,iDim5,idmat) = kCA(sCk+iC,sAk+iA,iDim5,idmat) + factor * kCATMPMAT(iC,iA,idmat)
  ENDDO
  DO iD=1,nD
     kDA(sDk+iD,sAk+iA,iDim5,idmat) = kDA(sDk+iD,sAk+iA,iDim5,idmat) + factor * kDATMPMAT(iD,iA,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE kCA_DB_kDA_CB


SUBROUTINE Kfull(kAC,dBD,KAD,DBC,KBC,DAD,KBD,DAC,kCA,dDB,kDA,dCB,kCB,dDA,kDB,dCA,&
     & nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd, &
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nAk,nBk,nCk,nDk,sAk,sBK,sCk,sDK,nAd,nBd,nCd,nDd,sAd,sBd,sCd,sDd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kAC(nAk,nCk,ndim5output,ndmat),kAD(nAk,nDk,ndim5output,ndmat)
Real(realk),intent(INOUT) :: kBC(nBk,nCk,ndim5output,ndmat),kBD(nBk,nDk,ndim5output,ndmat)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output,ndmat),kDA(nDk,nAk,ndim5output,ndmat)
Real(realk),intent(INOUT) :: kCB(nCk,nBk,ndim5output,ndmat),kDB(nDk,nBk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dBD(nBd,nDd,ndmat),dBC(nBd,nCd,ndmat),dAD(nAd,nDd,ndmat),dAC(nAd,nCd,ndmat)
Real(realk),intent(IN)    :: dDB(nDd,nBd,ndmat),dCB(nCd,nBd,ndmat),dDA(nDd,nAd,ndmat),dCA(nCd,nAd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: kBDtmp,kADtmp,kDBtmp,kDAtmp,dBDtmp,dADtmp,dDBtmp,dDAtmp,int,kBCtmp,dBCtmp
real(realk),parameter :: D0=0E0_realk
!
!$OMP CRITICAL (distributeFockBlock)
DO iD=1,nD
 DO iC=1,nC
  DO iB=1,nB
   DO idmat=1,ndmat
    kBDtmp = D0
    kBCtmp = D0
    dBCtmp = dBC(sBd+iB,sCd+iC,idmat)
    dBDtmp = dBD(sBd+iB,sDd+iD,idmat)
    DO iA=1,nA
     int = factor * CDAB(iC,iD,iA,iB,iDeriv,iPass)
     kAD(sAk+iA,sDk+iD,idim5,idmat) = kAD(sAk+iA,sDk+iD,idim5,idmat) + int * dBCtmp
     kAC(sAk+iA,sCk+iC,idim5,idmat) = kAC(sAk+iA,sCk+iC,idim5,idmat) + int * dBDtmp
     kBDtmp = kBDtmp + int * dAC(sAd+iA,sCd+iC,idmat)
     kBCtmp = kBCtmp + int * dAD(sAd+iA,sDd+iD,idmat)
    ENDDO
    kBD(sBk+iB,sDk+iD,idim5,idmat)= kBD(sBk+iB,sDk+iD,idim5,idmat) + kBDtmp
    kBC(sBk+iB,sCk+iC,idim5,idmat) = kBC(sBk+iB,sCk+iC,idim5,idmat) + kBCtmp
   ENDDO
  ENDDO
 ENDDO
ENDDO

DO iB=1,nB
 DO iA=1,nA
  DO iD=1,nD
   DO idmat=1,ndmat
    kDBtmp = D0
    kDAtmp = D0
    dDBtmp = dDB(sDd+iD,sBd+iB,idmat)
    dDAtmp = dDA(sDd+iD,sAd+iA,idmat)
    DO iC=1,nC
     int = factor * CDAB(iC,iD,iA,iB,iDeriv,iPass)
     kCA(sCk+iC,sAk+iA,idim5,idmat) = kCA(sCk+iC,sAk+iA,idim5,idmat) + int * dDBtmp
     kCB(sCk+iC,sBk+iB,idim5,idmat) = kCB(sCk+iC,sBk+iB,idim5,idmat) + int * dDAtmp
     kDBtmp = kDBtmp + int * dCA(sCd+iC,sAd+iA,idmat)
     kDAtmp = kDAtmp + int * dCB(sCd+iC,sBd+iB,idmat)
    ENDDO
    kDB(sDk+iD,sBk+iB,idim5,idmat) = kDB(sDk+iD,sBk+iB,idim5,idmat) + kDBtmp
    kDA(sDk+iD,sAk+iA,idim5,idmat) = kDA(sDk+iD,sAk+iA,idim5,idmat) + kDAtmp
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE Kfull

SUBROUTINE kAC_BD(kAC,dBD,nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kAC(nAk,nCk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dBD(nBd,nDd,ndmat)
Real(realk),intent(IN)    :: factor
!
Real(realk) :: kACTMPMAT(nA,nC,ndmat)
Integer :: iA,iB,iC,iD,idmat
real(realk) :: dBDTMP
!
DO idmat=1,ndmat
 DO iC=1,nC
  DO iA=1,nA
   kACTMPMAT(iA,iC,idmat) = 0E0_realk
  ENDDO
 ENDDO
ENDDO

DO iB=1,nB
 DO iD=1,nD
  DO idmat=1,ndmat
   dBDTMP = dBD(sBd+iB,sDd+iD,idmat)
   DO iA=1,nA
    DO iC=1,nC
     kACTMPMAT(iA,iC,idmat) = kACTMPMAT(iA,iC,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dBDTMP
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iC=1,nC
  DO iA=1,nA
   kAC(sAk+iA,sCk+iC,idim5,idmat) = kAC(sAk+iA,sCk+iC,idim5,idmat) + factor * kACTMPMAT(iA,iC,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE kAC_BD

SUBROUTINE kBC_AD(kBC,dAD,nBk,nCk,sBk,sCk,nAd,nDd,sAs,sDd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nBk,nCk,sBk,sCk,nAd,nDd,sAs,sDd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kBC(nBk,nCk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dAD(nAd,nDd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
Real(realk) :: tmp
!
!$OMP CRITICAL (distributeFockBlock)
DO iD=1,nD
 DO iA=1,nA
  DO idmat=1,ndmat
   tmp = factor * dAD(sAd+iA,sDd+iD,idmat)
   DO iB=1,nB
    DO iC=1,nC
     kBC(sBk+iB,sCk+iC,idim5,idmat) = kBC(sBk+iB,sCk+iC,idim5,idmat) + &
     & CDAB(iC,iD,iA,iB,iDeriv,iPass) * tmp
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)
END SUBROUTINE kBC_AD

SUBROUTINE kBD_AC(kBD,dAC,nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kBD(nBk,nDk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dAC(nAd,nCd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP
!
DO iD=1,nD
 DO iB=1,nB
  DO idmat=1,ndmat
   tmp = 0.0E0_realk
   DO iA=1,nA
    DO iC=1,nC
     tmp = tmp + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dAC(sAd+iA,sCd+iC,idmat)
    ENDDO
   ENDDO
!$OMP CRITICAL (distributeFockBlock)
   kBD(sBk+iB,sDk+iD,idim5,idmat) = kBD(sBk+iB,sDk+iD,idim5,idmat) + factor * tmp
!$OMP END CRITICAL (distributeFockBlock)
  ENDDO
 ENDDO
ENDDO
END SUBROUTINE kBD_AC

SUBROUTINE kAD_BC(kAd,dBC,nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd,&
& CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kAD(nAk,nDk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dBC(nBd,nCd,ndmat)
Real(realk),intent(IN)    :: factor
!
real(realk) :: TMP
real(realk),parameter :: D0 = 0E0_realk
Integer :: iA,iB,iC,iD,idmat
!
DO iA=1,nA
 DO iD=1,nD
  DO idmat=1,ndmat
   tmp = 0.0E0_realk
   DO iB=1,nB
    DO iC=1,nC
     tmp = tmp + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dBC(sBd+iB,sCd+iC,idmat)
    ENDDO
   ENDDO
!$OMP CRITICAL (distributeFockBlock)
   kAD(sAk+iA,sDk+iD,idim5,idmat) = kAD(sAk+iA,sDk+iD,idim5,idmat) + factor * tmp
!$OMP END CRITICAL (distributeFockBlock)
  ENDDO
 ENDDO
ENDDO

END SUBROUTINE kAD_BC

SUBROUTINE kCA_DB(kCA,dDB,nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nAk,nCk,sAk,sCk,nBd,nDd,sBd,sDd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCA(nCk,nAk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dDB(nDd,nBd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP
real(realk) :: kCATMPMAT(nC,nA,ndmat)
real(realk),parameter :: D0=0E0_realk
!
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCATMPMAT(iC,iA,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
ENDDO
DO iB=1,nB
 DO iD=1,nD
  DO idmat=1,ndmat
   TMP = factor*dDB(sDd+iD,sBd+iB,idmat)
   DO iA=1,nA
    DO iC=1,nC
     kCATMPMAT(iC,iA,idmat) = kCATMPMAT(iC,iA,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass)*TMP
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iA=1,nA
  DO iC=1,nC
   kCA(sCk+iC,sAk+iA,idim5,idmat) = kCA(sCk+iC,sAk+iA,idim5,idmat) + kCATMPMAT(iC,iA,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)

END SUBROUTINE kCA_DB

SUBROUTINE kCB_DA(kCB,dDA,nBk,nCk,sBk,sCk,nAd,nDd,sAd,sDd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nBk,nCk,sBk,sCk,nAd,nDd,sAd,sDd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kCB(nCk,nBk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dDA(nDd,nAd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP
real(realk) :: kCBTMPMAT(nC,nB,ndmat)
real(realk),parameter :: D0=0E0_realk
!
DO idmat=1,ndmat
 DO iB=1,nB
  DO iC=1,nC
   kCBTMPMAT(iC,iB,idmat) = 0.0E0_realk
  ENDDO
 ENDDO
ENDDO
DO iA=1,nA
 DO iD=1,nD
  DO idmat=1,ndmat
   TMP = factor*dDA(sDd+iD,sAd+iA,idmat)
   DO iB=1,nB
    DO iC=1,nC
     kCBTMPMAT(iC,iB,idmat) = kCBTMPMAT(iC,iB,idmat) + CDAB(iC,iD,iA,iB,iDeriv,iPass) * TMP
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO idmat=1,ndmat
 DO iB=1,nB
  DO iC=1,nC
   kCB(sCk+iC,sBk+iB,idim5,idmat) = kCB(sCk+iC,sBk+iB,idim5,idmat) + kCBTMPMAT(iC,iB,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)
END SUBROUTINE kCB_DA

SUBROUTINE kDB_CA(kDB,dCA,nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nBk,nDk,sBk,sDk,nAd,nCd,sAd,sCd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kDB(nDk,nBk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dCA(nCd,nAd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP
real(realk),parameter :: D0=0E0_realk
!
DO iB=1,nB
 DO iD=1,nD
  DO idmat=1,ndmat
   TMP = D0
   DO iA=1,nA
    DO iC=1,nC
     TMP  = TMP + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dCA(sCd+iC,sAd+iA,idmat)
    ENDDO
   ENDDO
!$OMP CRITICAL (distributeFockBlock)
   kDB(sDk+iD,sBk+iB,idim5,idmat) = kDB(sDk+iD,sBk+iB,idim5,idmat) + factor * TMP
!$OMP END CRITICAL (distributeFockBlock)
  ENDDO
 ENDDO
ENDDO
END SUBROUTINE kDB_CA

SUBROUTINE kDA_CB(kDA,dCB,nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd,&
     & CDAB,factor,nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,&
     & ndim5,ndim5output,ndmat,lupri)
implicit none
Integer,intent(IN)        :: nA,nB,nC,nD,iPass,ideriv,idim5,nPasses,ndim5,ndim5output,lupri,ndmat
Integer,intent(IN)        :: nAk,nDk,sAk,sDk,nBd,nCd,sBd,sCd
Real(realk),intent(IN)    :: CDAB(nC,nD,nA,nB,ndim5,nPasses)
Real(realk),intent(INOUT) :: kDA(nDk,nAk,ndim5output,ndmat)
Real(realk),intent(IN)    :: dCB(nCd,nBd,ndmat)
Real(realk),intent(IN)    :: factor
!
Integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP,kDATMPMAT(nD,nA,ndmat)
real(realk),parameter :: D0=0E0_realk
!
DO iA=1,nA
 DO iD=1,nD
  DO idmat=1,ndmat
   TMP = D0
   DO iB=1,nB
    DO iC=1,nC
     TMP = TMP + CDAB(iC,iD,iA,iB,iDeriv,iPass) * dCB(sCd+iC,sBd+iB,idmat)
    ENDDO
   ENDDO
   kDATMPMAT(iD,iA,idmat) = factor * TMP
  ENDDO
 ENDDO
ENDDO
!$OMP CRITICAL (distributeFockBlock)
DO iA=1,nA
 DO iD=1,nD
  DO idmat=1,ndmat
   kDA(sDk+iD,sAk+iA,idim5,idmat) = kDA(sDk+iD,sAk+iA,idim5,idmat) + kDATMPMAT(iD,iA,idmat)
  ENDDO
 ENDDO
ENDDO
!$OMP END CRITICAL (distributeFockBlock)
END SUBROUTINE kDA_CB

END SUBROUTINE distributeExchange

!> \brief Distribute exchange-type integrals
!> \author \latexonly S. Reine  \endlatexonly
!> \date 2011-03-08
!> \param Kmat contains the result lstensor
!> \param CDAB matrix containing calculated integrals
!> \param Dmat contains the rhs-density matrix/matrices
!> \param ndmat number of rhs-density matries
!> \param PQ information about the calculated integrals (to be distributed)
!> \param Input contain info about the requested integral 
!> \param Lsoutput contain info about the requested output, and actual output
!> \param LUPRI logical unit number for output printing
!> \param IPRINT integer containing printlevel
SUBROUTINE distributeKgrad(Kgrad,CDAB,Dlhs,Drhs,ndmat,PQ,Input,&
    &                      Lsoutput,LUPRI,IPRINT)
implicit none 
Type(integrand),intent(in)         :: PQ
Type(IntegralInput),intent(in)     :: Input
Type(IntegralOutput),intent(inout) :: Lsoutput
Integer,intent(in)                 :: ndmat,LUPRI,IPRINT
REAL(REALK),pointer                :: CDAB(:)
TYPE(lstensor),intent(inout)       :: Kgrad
TYPE(lstensor),intent(in)          :: Dlhs,Drhs
!
type(overlap),pointer :: P,Q
logical :: SamePQ,SameLHSaos,SameRHSaos,SameODs
Logical :: permuteAB,permuteCD,permuteOD
integer :: nAngmomP,nDeriv,nPasses,iLSAO
integer :: iPass,iPassP,iPassQ,iDeriv,iDerivP,iDerivQ,geoderivorder,iAtom,iDer
integer :: nA,nB,nC,nD,batchA,batchB,batchC,batchD,atomA,atomB,atomC,atomD
!integer :: indLAC,indLBC,indLAD,indLBD,indRBD,indRAD,indRBC,indRAC
!integer :: indLCA,indLCB,indLDA,indLDB,indRDB,indRDA,indRCB,indRCA
integer :: CA,DB,CB,DA,maxAng,maxBat
integer :: AC,BD,niderindex
integer :: nl1,nl2,nl3,nl4,sl1,sl2,sl3,sl4,nr1,nr2,nr3,nr4,sr1,sr2,sr3,sr4
Real(realk),pointer :: lAC(:),lBC(:),lAD(:),lBD(:),rBD(:),rAD(:),rBC(:),rAC(:)
Real(realk),pointer :: lCA(:),lCB(:),lDA(:),lDB(:),rDB(:),rDA(:),rCB(:),rCA(:)
Real(realk),pointer :: kelms(:)
real(realk),pointer :: ltheta(:,:,:,:)
integer :: iLSAOindex(PQ%P%p%nPasses*PQ%Q%p%nPasses*Input%ngeoderivcomp)
integer :: iderindex(PQ%P%p%nPasses*PQ%Q%p%nPasses*Input%ngeoderivcomp)
real(realk) :: idertmp(PQ%P%p%nPasses*PQ%Q%p%nPasses*Input%ngeoderivcomp)
integer,parameter,dimension(4) :: permuteAO = (/1,3,2,4/)

Type(derivativeInfo) :: derivInfo
Real(realk) :: tmp
P => PQ%P%p
Q => PQ%Q%p
nAngmomP   = P%nAngmom
SamePQ     = PQ%samePQ
SameLHSaos = INPUT%SameLHSaos
SameRHSaos = INPUT%SameRHSaos
SameODs    = INPUT%SameODs
nDeriv     = Input%ngeoderivcomp
geoderivorder = Input%geoderivorder
CALL initDerivativeOverlapInfo(derivInfo,PQ,Input)
IF (IPRINT.GT. 50) THEN
  CALL printDerivativeOverlapInfo(derivInfo,LUPRI)
ENDIF

niderindex = 0
nPasses = P%nPasses*Q%nPasses
iPass = 0
DO iPassP=1,P%nPasses
  atomA  = P%orb1atom(iPassP)
  batchA = P%orb1batch(iPassP)
  nA     = P%orbital1%totOrbitals
  atomB  = P%orb2atom(iPassP)
  batchB = P%orb2batch(iPassP)
  nB     = P%orbital2%totOrbitals
  derivInfo%Atom(1)=atomA
  derivInfo%Atom(2)=atomB

  permuteAB  = SameLHSaos.AND.((batchA.NE.batchB).OR.(atomA.NE.atomB))
  DO iPassQ=1,Q%nPasses
    iPass = iPass + 1

    atomC  = Q%orb1atom(iPassQ)
    batchC = Q%orb1batch(iPassQ)
    nC     = Q%orbital1%totOrbitals
    atomD  = Q%orb2atom(iPassQ)
    batchD = Q%orb2batch(iPassQ)
    nD     = Q%orbital2%totOrbitals
    derivInfo%Atom(3)=atomC
    derivInfo%Atom(4)=atomD
    permuteCD = SameRHSaos.AND.((batchC.NE.batchD).OR.(atomC.NE.atomD))
    permuteOD = SameODs.AND.( ((batchA.NE.batchC).OR.(atomA.NE.atomC)).OR.&
   &                          ((batchB.NE.batchD).OR.(atomB.NE.atomD)) )
    permuteOD = SameODs.AND..NOT.((batchA.EQ.batchC).AND.(atomA.EQ.atomC).AND.&
   &                          (batchB.EQ.batchD).AND.(atomB.EQ.atomD) )

    call mem_alloc(ltheta,nC,nD,nA,nB)
    ltheta = 0E0_realk
    IF (permuteAB.AND.permuteCD) THEN
       CA = Dlhs%index(atomC,atomA,1,1)
       lCA => Dlhs%lsao(CA)%elms
       DB = Dlhs%index(atomD,atomB,1,1)
       lDB => Dlhs%lsao(DB)%elms
       
       nl3 = Dlhs%lsao(CA)%nLocal(1) 
       nl1 = Dlhs%lsao(CA)%nLocal(2) 
       nl4 = Dlhs%lsao(DB)%nLocal(1) 
       nl2 = Dlhs%lsao(DB)%nLocal(2) 
       maxAng = Dlhs%lsao(CA)%maxAng
       maxBat = Dlhs%lsao(CA)%maxBat
       sl3 = Dlhs%lsao(CA)%startLocalOrb(1+(batchC-1)*maxAng)-1
       sl1 = Dlhs%lsao(CA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1
       maxAng = Dlhs%lsao(DB)%maxAng
       maxBat = Dlhs%lsao(DB)%maxBat
       sl4 = Dlhs%lsao(DB)%startLocalOrb(1+(batchD-1)*maxAng)-1
       sl2 = Dlhs%lsao(DB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1

       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms

       DB = Drhs%index(atomD,atomB,1,1)
       rDB => Drhs%lsao(DB)%elms
       CA = Drhs%index(atomC,atomA,1,1)
       rCA => Drhs%lsao(CA)%elms
       
       nr4 = Drhs%lsao(DB)%nLocal(1) 
       nr2 = Drhs%lsao(DB)%nLocal(2) 
       nr3 = Drhs%lsao(CA)%nLocal(1) 
       nr1 = Drhs%lsao(CA)%nLocal(2) 
       maxAng = Drhs%lsao(DB)%maxAng
       maxBat = Drhs%lsao(DB)%maxBat
       sr4 = Drhs%lsao(DB)%startLocalOrb(1+(batchD-1)*maxAng)-1
       sr2 = Drhs%lsao(DB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1
       maxAng = Drhs%lsao(CA)%maxAng
       maxBat = Drhs%lsao(CA)%maxBat
       sr3 = Drhs%lsao(CA)%startLocalOrb(1+(batchC-1)*maxAng)-1
       sr1 = Drhs%lsao(CA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1

       DA = Drhs%index(atomD,atomA,1,1)
       rDA => Drhs%lsao(DA)%elms
       CB = Drhs%index(atomC,atomB,1,1)
       rCB => Drhs%lsao(CB)%elms

       call build_ltheta_TT(ltheta,lCA,rDB,lCB,rDA,lDA,rCB,lDB,rCA,&
            & nl1,nl2,nl3,nl4,sl1,sl2,sl3,sl4,nr1,nr2,nr3,nr4,sr1,sr2,sr3,sr4,nA,nB,nC,nD,ndmat)
    ELSE IF (permuteAB) THEN
       CA = Dlhs%index(atomC,atomA,1,1)
       lCA => Dlhs%lsao(CA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       
       nl3 = Dlhs%lsao(CA)%nLocal(1) 
       nl1 = Dlhs%lsao(CA)%nLocal(2) 
       nl2 = Dlhs%lsao(CB)%nLocal(2) 
       maxAng = Dlhs%lsao(CA)%maxAng
       maxBat = Dlhs%lsao(CA)%maxBat
       sl3 = Dlhs%lsao(CA)%startLocalOrb(1+(batchC-1)*maxAng)-1
       sl1 = Dlhs%lsao(CA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1
       maxAng = Dlhs%lsao(CB)%maxAng
       maxBat = Dlhs%lsao(CB)%maxBat
       sl2 = Dlhs%lsao(CB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1

       DB = Drhs%index(atomD,atomB,1,1)
       rDB => Drhs%lsao(DB)%elms
       DA = Drhs%index(atomD,atomA,1,1)
       rDA => Drhs%lsao(DA)%elms
       
       nr4 = Drhs%lsao(DB)%nLocal(1) 
       nr2 = Drhs%lsao(DB)%nLocal(2) 
       nr1 = Drhs%lsao(DA)%nLocal(2) 
       maxAng = Drhs%lsao(DB)%maxAng
       maxBat = Drhs%lsao(DB)%maxBat
       sr4 = Drhs%lsao(DB)%startLocalOrb(1+(batchD-1)*maxAng)-1
       sr2 = Drhs%lsao(DB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1
       maxAng = Drhs%lsao(DA)%maxAng
       maxBat = Drhs%lsao(DA)%maxBat
       sr1 = Drhs%lsao(DA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1

       call build_ltheta_TF(ltheta,lCA,rDB,lCB,rDA,&
            & nl1,nl2,nl3,sl1,sl2,sl3,nr1,nr2,nr4,sr1,sr2,sr4,&
            & nA,nB,nC,nD,ndmat)
    ELSE IF (permuteCD) THEN
       CA = Dlhs%index(atomC,atomA,1,1)
       lCA => Dlhs%lsao(CA)%elms
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       
       nl3 = Dlhs%lsao(CA)%nLocal(1) 
       nl1 = Dlhs%lsao(CA)%nLocal(2) 
       nl4 = Dlhs%lsao(DA)%nLocal(1) 
       maxAng = Dlhs%lsao(CA)%maxAng
       maxBat = Dlhs%lsao(CA)%maxBat
       sl3 = Dlhs%lsao(CA)%startLocalOrb(1+(batchC-1)*maxAng)-1
       sl1 = Dlhs%lsao(CA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1
       maxAng = Dlhs%lsao(DA)%maxAng
       maxBat = Dlhs%lsao(DA)%maxBat
       sl4 = Dlhs%lsao(DA)%startLocalOrb(1+(batchD-1)*maxAng)-1

       DB = Drhs%index(atomD,atomB,1,1)
       rDB => Drhs%lsao(DB)%elms
       CB = Drhs%index(atomC,atomB,1,1)
       rCB => Drhs%lsao(CB)%elms
       
       nr4 = Drhs%lsao(DB)%nLocal(1) 
       nr2 = Drhs%lsao(DB)%nLocal(2) 
       nr3 = Drhs%lsao(CB)%nLocal(1) 
       maxAng = Drhs%lsao(DB)%maxAng
       maxBat = Drhs%lsao(DB)%maxBat
       sr4 = Drhs%lsao(DB)%startLocalOrb(1+(batchD-1)*maxAng)-1
       sr2 = Drhs%lsao(DB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1
       maxAng = Drhs%lsao(CB)%maxAng
       maxBat = Drhs%lsao(CB)%maxBat
       sr3 = Drhs%lsao(CB)%startLocalOrb(1+(batchC-1)*maxAng)-1

       call build_ltheta_FT(ltheta,lCA,rDB,lDA,rCB,&
            & nl1,nl3,nl4,sl1,sl3,sl4,nr2,nr3,nr4,sr2,sr3,sr4,&
            & nA,nB,nC,nD,ndmat)
    ELSE
       AC = Dlhs%index(atomA,atomC,1,1)
       lAC => Dlhs%lsao(AC)%elms
       
       nl1 = Dlhs%lsao(AC)%nLocal(1) 
       nl3 = Dlhs%lsao(AC)%nLocal(2) 
       maxAng = Dlhs%lsao(AC)%maxAng
       maxBat = Dlhs%lsao(AC)%maxBat
       sl1 = Dlhs%lsao(AC)%startLocalOrb(1+(batchA-1)*maxAng)-1
       sl3 = Dlhs%lsao(AC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat)-1

       BD = Drhs%index(atomB,atomD,1,1)
       rBD => Drhs%lsao(BD)%elms
       
       nr2 = Drhs%lsao(BD)%nLocal(1) 
       nr4 = Drhs%lsao(BD)%nLocal(2) 
       maxAng = Drhs%lsao(BD)%maxAng
       maxBat = Drhs%lsao(BD)%maxBat
       sr2 = Drhs%lsao(BD)%startLocalOrb(1+(batchB-1)*maxAng)-1
       sr4 = Drhs%lsao(BD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat)-1
       call build_ltheta_FF(ltheta,lAC,rBD,&
            & nl1,nl3,sl1,sl3,nr2,nr4,sr2,sr4,&
            & nA,nB,nC,nD,ndmat)
    ENDIF
    DO iDeriv=1,nDeriv

      tmp = gtheta(ltheta,CDAB,nA,nB,nC,nD,iPass,iDeriv,nPasses,nDeriv,lupri)

      iDer  = derivInfo%dirComp(iDeriv)
      iAtom = derivInfo%Atom(derivInfo%AO(1,iDeriv))
!The structure of the lstensor when used to store the molecular gradient
!is maybe not the most logical and we refer to discussion in the subroutine
!init_gradientlstensor in lsutil/lstensor_operations.f90
      iLSAO = Kgrad%INDEX(iAtom,1,1,permuteAO(derivInfo%AO(1,iDeriv)))
#ifdef VAR_DEBUGINT
      IF(iLSAO.EQ. 0)THEN
         WRITE(lupri,*)'iLSAO is zero - for some reason'
         WRITE(lupri,*)'iAtom          ',iAtom
         WRITE(lupri,*)'Center (1-4) = ',derivInfo%AO(1,iDeriv)
         WRITE(lupri,*)'Error in use of gradientlstensor distributeKgrad'
         CALL LSQUIT('Error in use of gradientlstensor distributeKgrad',lupri)
      ENDIF
#endif
      niderindex = niderindex + 1
      iLSAOindex(niderindex) = iLSAO
      iderindex(niderindex) = ider
      idertmp(niderindex) = tmp
!!$OMP ATOMIC
!      Kgrad%LSAO(iLSAO)%elms(iDer) = Kgrad%LSAO(iLSAO)%elms(iDer) - 0.5E0_realk*tmp
    ENDDO !iDeriv
    call mem_dealloc(ltheta)
  ENDDO !iPassQ
ENDDO !iPassP
!!$OMP CRITICAL (distributeKgradBlock)
do iDeriv=1,niderindex
 iLSAO = iLSAOindex(iDeriv)
 ider = iderindex(iDeriv)
 tmp = idertmp(iDeriv)
!$OMP ATOMIC
 Kgrad%LSAO(iLSAO)%elms(iDer) = Kgrad%LSAO(iLSAO)%elms(iDer) - 0.5E0_realk*tmp
enddo
!!$OMP END CRITICAL (distributeKgradBlock)

CALL freeDerivativeOverlapInfo(derivInfo)

CONTAINS
FUNCTION gtheta(ltheta,CDAB,nA,nB,nC,nD,iPass,iDeriv,nPasses,nDeriv,lupri)
implicit none
integer,intent(IN) :: nA,nB,nC,nD,iPass,iDeriv,nPasses,nDeriv,lupri
real(realk),intent(IN) :: ltheta(nC*nD*nA*nB)
Real(realk),intent(IN) :: CDAB(nC*nD*nA*nB,nDeriv,nPasses)
Real(realk)            :: gtheta
!
Integer     :: i
Real(realk) :: tmp
!
gtheta = 0E0_realk
DO i=1,nC*nD*nA*nB
  gtheta = gtheta + ltheta(i)*CDAB(i,iDeriv,iPass)
ENDDO

END FUNCTION gtheta

SUBROUTINE build_ltheta_TT(ltheta,lCA,rDB,lCB,rDA,lDA,rCB,lDB,rCA,&
     & nl1,nl2,nl3,nl4,sl1,sl2,sl3,sl4,nr1,nr2,nr3,nr4,sr1,sr2,sr3,sr4,nA,nB,nC,nD,ndmat)
implicit none
integer,intent(IN) :: nA,nB,nC,nD,ndmat
integer,intent(IN) :: nl1,nl2,nl3,nl4,sl1,sl2,sl3,sl4,nr1,nr2,nr3,nr4,sr1,sr2,sr3,sr4                      
real(realk) :: ltheta(nC,nD,nA,nB)
real(realk) :: lCA(nl3,nl1,ndmat)!(nC,nA,ndmat)
real(realk) :: lDA(nl4,nl1,ndmat)!(nD,nA,ndmat)
real(realk) :: lCB(nl3,nl2,ndmat)!(nC,nB,ndmat)
real(realk) :: lDB(nl4,nl2,ndmat)!(nD,nB,ndmat)
real(realk) :: rDB(nr4,nr2,ndmat)!(nD,nB,ndmat)
real(realk) :: rCB(nr3,nr2,ndmat)!(nC,nB,ndmat)
real(realk) :: rDA(nr4,nr1,ndmat)!(nD,nA,ndmat)
real(realk) :: rCA(nr3,nr1,ndmat)!(nC,nA,ndmat)
!
Integer :: idmat,iA,iB,iC,iD
!
real(realk),pointer :: ltheta_CADB(:,:,:,:)
real(realk),pointer :: ltheta_DACB(:,:,:,:)
real(realk),pointer :: ltheta_CBDA(:,:,:,:)
real(realk),pointer :: ltheta_DBCA(:,:,:,:)

IF (ndmat.GT.4) THEN
 call mem_alloc(ltheta_CADB,nC,nA,nD,nB)
 call mem_alloc(ltheta_DACB,nD,nA,nC,nB)
 call mem_alloc(ltheta_CBDA,nC,nB,nD,nA)
 call mem_alloc(ltheta_DBCA,nD,nB,nC,nA)
 call create_ltheta(ltheta_CADB,lCA,rDB,nl3,nl1,sl3,sl1,nr4,nr2,sr4,sr2,nC,nA,nD,nB,ndmat)
 call create_ltheta(ltheta_CBDA,lCB,rDA,nl3,nl2,sl3,sl2,nr4,nr1,sr4,sr1,nC,nB,nD,nA,ndmat)
 call create_ltheta(ltheta_DACB,lDA,rCB,nl4,nl1,sl4,sl1,nr3,nr2,sr3,sr2,nD,nA,nC,nB,ndmat)
 call create_ltheta(ltheta_DBCA,lDB,rCA,nl4,nl2,sl4,sl2,nr3,nr1,sr3,sr1,nD,nB,nC,nA,ndmat)
 DO iB=1,nB
  DO iD=1,nD
   DO iA=1,nA
    DO iC=1,nC
      ltheta(iC,iD,iA,iB) =   ltheta_CADB(iC,iA,iD,iB) + ltheta_DACB(iD,iA,iC,iB) &
      &                     + ltheta_CBDA(iC,iB,iD,iA) + ltheta_DBCA(iD,iB,iC,iA)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
 call mem_dealloc(ltheta_CADB)
 call mem_dealloc(ltheta_DACB)
 call mem_dealloc(ltheta_CBDA)
 call mem_dealloc(ltheta_DBCA)
ELSE
 DO idmat=1,ndmat
  DO iB=1,nB
   DO iD=1,nD
    DO iA=1,nA
     DO iC=1,nC
      ltheta(iC,iD,iA,iB) = ltheta(iC,iD,iA,iB) + lCA(sl3+iC,sl1+iA,idmat)*rDB(sr4+iD,sr2+iB,idmat) &
      & + lDA(sl4+iD,sl1+iA,idmat)*rCB(sr3+iC,sr2+iB,idmat) + lCB(sl3+iC,sl2+iB,idmat)*rDA(sr4+iD,sr1+iA,idmat) &
      & + lDB(sl4+iD,sl2+iB,idmat)*rCA(sr3+iC,sr1+iA,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
END SUBROUTINE build_ltheta_TT

SUBROUTINE build_ltheta_TF(ltheta,lCA,rDB,lCB,rDA,&
     & nl1,nl2,nl3,sl1,sl2,sl3,nr1,nr2,nr4,sr1,sr2,sr4,nA,nB,nC,nD,ndmat)
implicit none
integer,intent(IN) :: nA,nB,nC,nD,ndmat
integer,intent(IN) :: nl1,nl2,nl3,sl1,sl2,sl3,nr1,nr2,nr4,sr1,sr2,sr4                      
real(realk) :: ltheta(nC,nD,nA,nB)
real(realk) :: lCA(nl3,nl1,ndmat)!(nC,nA,ndmat)
real(realk) :: lCB(nl3,nl2,ndmat)!(nC,nB,ndmat)
real(realk) :: rDB(nr4,nr2,ndmat)!(nD,nB,ndmat)
real(realk) :: rDA(nr4,nr1,ndmat)!(nD,nA,ndmat)
!
Integer :: idmat,iA,iB,iC,iD
real(realk),pointer :: ltheta_CADB(:,:,:,:)
real(realk),pointer :: ltheta_CBDA(:,:,:,:)

IF (ndmat.GT.4) THEN
 call mem_alloc(ltheta_CADB,nC,nA,nD,nB)
 call mem_alloc(ltheta_CBDA,nC,nB,nD,nA)
 call create_ltheta(ltheta_CADB,lCA,rDB,nl3,nl1,sl3,sl1,nr4,nr2,sr4,sr2,nC,nA,nD,nB,ndmat)
 call create_ltheta(ltheta_CBDA,lCB,rDA,nl3,nl2,sl3,sl2,nr4,nr1,sr4,sr1,nC,nB,nD,nA,ndmat)

 DO iB=1,nB
  DO iD=1,nD
   DO iA=1,nA
    DO iC=1,nC
      ltheta(iC,iD,iA,iB) =   ltheta_CADB(iC,iA,iD,iB) + ltheta_CBDA(iC,iB,iD,iA)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
 call mem_dealloc(ltheta_CADB)
 call mem_dealloc(ltheta_CBDA)
ELSE
 DO idmat=1,ndmat
  DO iB=1,nB
   DO iD=1,nD
    DO iA=1,nA
     DO iC=1,nC
      ltheta(iC,iD,iA,iB) = ltheta(iC,iD,iA,iB) + lCA(sl3+iC,sl1+iA,idmat)*rDB(sr4+iD,sr2+iB,idmat) &
                                              & + lCB(sl3+iC,sl2+iB,idmat)*rDA(sr4+iD,sr1+iA,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
END SUBROUTINE build_ltheta_TF

SUBROUTINE build_ltheta_FT(ltheta,lCA,rDB,lDA,rCB,&
     & nl1,nl3,nl4,sl1,sl3,sl4,nr2,nr3,nr4,sr2,sr3,sr4,nA,nB,nC,nD,ndmat)
implicit none
integer,intent(IN) :: nA,nB,nC,nD,ndmat
integer,intent(IN) :: nl1,nl3,nl4,sl1,sl3,sl4,nr2,nr3,nr4,sr2,sr3,sr4                      
real(realk) :: ltheta(nC,nD,nA,nB)
real(realk) :: lCA(nl3,nl1,ndmat)!(nC,nA,ndmat)
real(realk) :: lDA(nl4,nl1,ndmat)!(nD,nA,ndmat)
real(realk) :: rDB(nr4,nr2,ndmat)!(nD,nB,ndmat)
real(realk) :: rCB(nr3,nr2,ndmat)!(nC,nB,ndmat)
!
Integer :: idmat,iA,iB,iC,iD
real(realk),pointer :: ltheta_CADB(:,:,:,:)
real(realk),pointer :: ltheta_DACB(:,:,:,:)

IF (ndmat.GT.4) THEN
 call mem_alloc(ltheta_CADB,nC,nA,nD,nB)
 call mem_alloc(ltheta_DACB,nD,nA,nC,nB)
 call create_ltheta(ltheta_CADB,lCA,rDB,nl3,nl1,sl3,sl1,nr4,nr2,sr4,sr2,nC,nA,nD,nB,ndmat)
 call create_ltheta(ltheta_DACB,lDA,rCB,nl4,nl1,sl4,sl1,nr3,nr2,sr3,sr2,nD,nA,nC,nB,ndmat)


 DO iB=1,nB
  DO iD=1,nD
   DO iA=1,nA
    DO iC=1,nC
      ltheta(iC,iD,iA,iB) =   ltheta_CADB(iC,iA,iD,iB) + ltheta_DACB(iD,iA,iC,iB)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
 call mem_dealloc(ltheta_CADB)
 call mem_dealloc(ltheta_DACB)
ELSE
 DO idmat=1,ndmat
  DO iB=1,nB
   DO iD=1,nD
    DO iA=1,nA
     DO iC=1,nC
      ltheta(iC,iD,iA,iB) = ltheta(iC,iD,iA,iB) + lCA(sl3+iC,sl1+iA,idmat)*rDB(sr4+iD,sr2+iB,idmat) &
           & + lDA(sl4+iD,sl1+iA,idmat)*rCB(sr3+iC,sr2+iB,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
END SUBROUTINE build_ltheta_FT

SUBROUTINE build_ltheta_FF(ltheta,lAC,rBD,&
     & nl1,nl3,sl1,sl3,nr2,nr4,sr2,sr4,nA,nB,nC,nD,ndmat)
implicit none
integer,intent(IN) :: nA,nB,nC,nD,ndmat
integer,intent(IN) :: nl1,nl3,sl1,sl3,nr2,nr4,sr2,sr4                      
real(realk) :: ltheta(nC,nD,nA,nB)
real(realk) :: lAC(nl1,nl3,ndmat)!(nA,nC,ndmat)
real(realk) :: rBD(nr2,nr4,ndmat)!(nB,nD,ndmat)
!
Integer :: idmat,iA,iB,iC,iD
real(realk),pointer :: ltheta_ACBD(:,:,:,:)
real(realk),pointer :: ltheta_DACB(:,:,:,:)

IF (ndmat.GT.4) THEN
 call mem_alloc(ltheta_ACBD,nA,nC,nB,nD)
 call create_ltheta(ltheta_ACBD,lAC,rBD,nl1,nl3,sl1,sl3,nr2,nr4,sr2,sr4,nA,nC,nB,nD,ndmat)

 DO iB=1,nB
  DO iD=1,nD
   DO iA=1,nA
    DO iC=1,nC
      ltheta(iC,iD,iA,iB) =   ltheta_ACBD(iA,iC,iB,iD)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
 call mem_dealloc(ltheta_ACBD)
ELSE
 DO idmat=1,ndmat
  DO iB=1,nB
   DO iD=1,nD
    DO iA=1,nA
     DO iC=1,nC
      ltheta(iC,iD,iA,iB) = ltheta(iC,iD,iA,iB) + lAC(sl1+iA,sl3+iC,idmat)*rBD(sr2+iB,sr4+iD,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
END SUBROUTINE build_ltheta_FF

SUBROUTINE create_ltheta(ltheta_PQ,P,Q,n1,n2,sA,sB,n3,n4,sC,sD,nA,nB,nC,nD,ndmat)
implicit none
integer,intent(IN)        :: nA,nB,nC,nD,n1,n2,n3,n4,sA,sB,sC,sD,ndmat
real(realk),intent(INOUT) :: ltheta_PQ(nA,nB,nC,nD)
real(realk),intent(IN)    :: P(n1,n2,ndmat)
real(realk),intent(IN)    :: Q(n3,n4,ndmat)
!
integer :: iA,iB,iC,iD,idmat
real(realk) :: TMP
ltheta_PQ = 0E0_realk
DO idmat=1,ndmat
 DO iD=1,nD
  DO iC=1,nC
   TMP = Q(sC+iC,sD+iD,idmat)
   DO iB=1,nB
    DO iA=1,nA
     ltheta_PQ(iA,iB,iC,iD) = ltheta_PQ(iA,iB,iC,iD) + P(sA+iA,sB+iB,idmat)*TMP
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDDO
END SUBROUTINE create_ltheta

END SUBROUTINE distributeKgrad

!> \brief Distribute exchange-type integrals
!> \author \latexonly S. Reine  \endlatexonly
!> \date 2011-03-08
!> \param Kmat contains the result lstensor
!> \param CDAB matrix containing calculated integrals
!> \param Dmat contains the rhs-density matrix/matrices
!> \param ndmat number of rhs-density matries
!> \param PQ information about the calculated integrals (to be distributed)
!> \param Input contain info about the requested integral 
!> \param Lsoutput contain info about the requested output, and actual output
!> \param LUPRI logical unit number for output printing
!> \param IPRINT integer containing printlevel
SUBROUTINE distributeKcont(CDAB,Dlhs,Drhs,ndmat,PQ,Input,&
    &                      Lsoutput,Kcont,LUPRI,IPRINT)
implicit none 
Type(integrand),intent(in)         :: PQ
Type(IntegralInput),intent(in)     :: Input
Type(IntegralOutput),intent(inout) :: Lsoutput
Integer,intent(in)                 :: ndmat,LUPRI,IPRINT
REAL(REALK),pointer                :: CDAB(:)
TYPE(lstensor),intent(in)          :: Dlhs,Drhs
Real(Realk),intent(inout)          :: Kcont(ndmat)
!
type(overlap),pointer :: P,Q
logical :: SamePQ,SameLHSaos,SameRHSaos,SameODs
Logical :: permuteAB,permuteCD,permuteOD
integer :: nAngmomP,nPasses,maxBat,maxAng
integer :: iPass,iPassP,iPassQ,idmat,DAr,CBr
integer :: nA,nB,nC,nD,batchA,batchB,batchC,batchD,atomA,atomB,atomC,atomD
integer :: AC,BD,DA,CB,AD,BC,n1,n2,n3,n4,s1,s2,s3,s4
integer :: CA,DB
Real(realk),pointer :: lAC(:),lBC(:),lAD(:),lBD(:),rBD(:),rAD(:),rBC(:),rAC(:)
Real(realk),pointer :: lCA(:),lCB(:),lDA(:),lDB(:),rDB(:),rDA(:),rCB(:),rCA(:)
Real(realk) :: tmpKcont(ndmat)
#ifdef VAR_LSMPI
!We assume sym dmat

P => PQ%P%p
Q => PQ%Q%p
nAngmomP   = P%nAngmom
SamePQ     = PQ%samePQ
SameLHSaos = INPUT%SameLHSaos
SameRHSaos = INPUT%SameRHSaos
SameODs    = INPUT%SameODs
nPasses = P%nPasses*Q%nPasses
iPass = 0
tmpKcont = 0E0_realk
nA     = P%orbital1%totOrbitals
nB     = P%orbital2%totOrbitals
nC     = Q%orbital1%totOrbitals
nD     = Q%orbital2%totOrbitals
DO iPassP=1,P%nPasses
  atomA  = P%orb1atom(iPassP)
  batchA = P%orb1batch(iPassP)
  atomB  = P%orb2atom(iPassP)
  batchB = P%orb2batch(iPassP)

  permuteAB  = SameLHSaos.AND.((batchA.NE.batchB).OR.(atomA.NE.atomB))
  DO iPassQ=1,Q%nPasses
    iPass = iPass + 1

    atomC  = Q%orb1atom(iPassQ)
    batchC = Q%orb1batch(iPassQ)
    atomD  = Q%orb2atom(iPassQ)
    batchD = Q%orb2batch(iPassQ)
    permuteCD = SameRHSaos.AND.((batchC.NE.batchD).OR.(atomC.NE.atomD))
    permuteOD = SameODs.AND.( ((batchA.NE.batchC).OR.(atomA.NE.atomC)).OR.&
   &                          ((batchB.NE.batchD).OR.(atomB.NE.atomD)) )
    permuteOD = SameODs.AND..NOT.((batchA.EQ.batchC).AND.(atomA.EQ.atomC).AND.&
   &                          (batchB.EQ.batchD).AND.(atomB.EQ.atomD) )


    AC = Dlhs%index(atomA,atomC,1,1)
    lAC => Dlhs%lsao(AC)%elms       
    n1 = Dlhs%lsao(AC)%nLocal(1) 
    n3 = Dlhs%lsao(AC)%nLocal(2) 
    maxAng = Dlhs%lsao(AC)%maxAng
    maxBat = Dlhs%lsao(AC)%maxBat
    s1 = Dlhs%lsao(AC)%startLocalOrb(1+(batchA-1)*maxAng)-1
    s3 = Dlhs%lsao(AC)%startLocalOrb(1+(batchC-1)*maxAng+maxAng*maxBat)-1

    BD = Drhs%index(atomB,atomD,1,1)
    rBD => Drhs%lsao(BD)%elms
       
    n2 = Drhs%lsao(BD)%nLocal(1) 
    n4 = Drhs%lsao(BD)%nLocal(2) 
    maxAng = Drhs%lsao(BD)%maxAng
    maxBat = Drhs%lsao(BD)%maxBat
    s2 = Drhs%lsao(BD)%startLocalOrb(1+(batchB-1)*maxAng)-1
    s4 = Drhs%lsao(BD)%startLocalOrb(1+(batchD-1)*maxAng+maxAng*maxBat)-1

    IF (permuteCD) THEN
       AD = Dlhs%index(atomA,atomD,1,1)
       lAD => Dlhs%lsao(AD)%elms       
       BC = Drhs%index(atomB,atomC,1,1)
       rBC => Drhs%lsao(BC)%elms
    ENDIF
    IF (permuteAB) THEN
       BD = Dlhs%index(atomB,atomD,1,1)
       lBD => Dlhs%lsao(BD)%elms       
       AC = Drhs%index(atomA,atomC,1,1)
       rAC => Drhs%lsao(AC)%elms

       AD = Drhs%index(atomA,atomD,1,1)
       rAD => Drhs%lsao(AD)%elms       
       BC = Dlhs%index(atomB,atomC,1,1)
       lBC => Dlhs%lsao(BC)%elms
    ENDIF
    IF (permuteAB.AND.permuteCD) THEN
       call fullEcont2(tmpKcont,lAC,lBC,lAD,lBD,rBD,rAD,rBC,rAC,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,permuteOD,lupri)
    ELSE IF (permuteAB) THEN
       call fullEcont3(tmpKcont,lAC,lBC,rBD,rAD,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,permuteOD,lupri)
    ELSE IF (permuteCD) THEN       
       call fullEcont4(tmpKcont,lAC,lAD,rBD,rBC,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,permuteOD,lupri)
    ELSE
       call fullEcont5(tmpKcont,lAC,rBD,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,permuteOD,lupri)
    ENDIF
  ENDDO !iPassQ
ENDDO !iPassP

!reduction afterwards
!!$OMP CRITICAL (distributeKgradBlock)
DO idmat=1,ndmat
   Kcont(idmat) = Kcont(idmat) - tmpKcont(idmat)
ENDDO
!!$OMP END CRITICAL (distributeKgradBlock)

#else
!Special for same lhs and rhs !!!!
!assumes same LHS and same RHS and symmetric matrices
!THIS DOES NOT HOLD FOR MPI....

P => PQ%P%p
Q => PQ%Q%p
nAngmomP   = P%nAngmom
SamePQ     = PQ%samePQ
SameLHSaos = INPUT%SameLHSaos
SameRHSaos = INPUT%SameRHSaos
SameODs    = INPUT%SameODs
nPasses = P%nPasses*Q%nPasses
iPass = 0
tmpKcont = 0E0_realk
DO iPassP=1,P%nPasses
  atomA  = P%orb1atom(iPassP)
  batchA = P%orb1batch(iPassP)
  nA     = P%orbital1%totOrbitals
  atomB  = P%orb2atom(iPassP)
  batchB = P%orb2batch(iPassP)
  nB     = P%orbital2%totOrbitals

  permuteAB  = SameLHSaos.AND.((batchA.NE.batchB).OR.(atomA.NE.atomB))
  DO iPassQ=1,Q%nPasses
    iPass = iPass + 1

    atomC  = Q%orb1atom(iPassQ)
    batchC = Q%orb1batch(iPassQ)
    nC     = Q%orbital1%totOrbitals
    atomD  = Q%orb2atom(iPassQ)
    batchD = Q%orb2batch(iPassQ)
    nD     = Q%orbital2%totOrbitals
    permuteCD = SameRHSaos.AND.((batchC.NE.batchD).OR.(atomC.NE.atomD))
    permuteOD = SameODs.AND.( ((batchA.NE.batchC).OR.(atomA.NE.atomC)).OR.&
   &                          ((batchB.NE.batchD).OR.(atomB.NE.atomD)) )
    permuteOD = SameODs.AND..NOT.((batchA.EQ.batchC).AND.(atomA.EQ.atomC).AND.&
   &                          (batchB.EQ.batchD).AND.(atomB.EQ.atomD) )

    CA = Dlhs%index(atomC,atomA,1,1)
    lCA => Dlhs%lsao(CA)%elms
    DB = Dlhs%index(atomD,atomB,1,1)
    lDB => Dlhs%lsao(DB)%elms       
    n3 = Dlhs%lsao(CA)%nLocal(1) 
    n1 = Dlhs%lsao(CA)%nLocal(2) 
    n4 = Dlhs%lsao(DB)%nLocal(1) 
    n2 = Dlhs%lsao(DB)%nLocal(2) 
    maxBat = Dlhs%lsao(CA)%maxBat
    maxAng = Dlhs%lsao(CA)%maxAng
    s3 = Dlhs%lsao(CA)%startLocalOrb(1+(batchC-1)*maxAng)-1
    s1 = Dlhs%lsao(CA)%startLocalOrb(1+(batchA-1)*maxAng+maxAng*maxBat)-1
    maxBat = Dlhs%lsao(DB)%maxBat
    maxAng = Dlhs%lsao(DB)%maxAng
    s4 = Dlhs%lsao(DB)%startLocalOrb(1+(batchD-1)*maxAng)-1
    s2 = Dlhs%lsao(DB)%startLocalOrb(1+(batchB-1)*maxAng+maxAng*maxBat)-1
    IF (permuteOD.AND.permuteCD.AND.permuteAB) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full1(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4, &
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
    ELSE IF (permuteOD.AND.permuteCD) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full2(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
     ELSE IF (permuteOD.AND.permuteAB) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full2(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
     ELSE IF (permuteAB.AND.permuteCD) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full2(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
      ELSE IF (permuteAB) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full3(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
      ELSE IF (permuteCD) THEN
       DA = Dlhs%index(atomD,atomA,1,1)
       lDA => Dlhs%lsao(DA)%elms
       CB = Dlhs%index(atomC,atomB,1,1)
       lCB => Dlhs%lsao(CB)%elms
       call full3(tmpKcont,lCA,lDA,lCB,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
     ELSE IF (permuteOD) THEN
       call full4(tmpKcont,lCA,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
     ELSE
       call full5(tmpKcont,lCA,lDB,n1,n2,n3,n4,s1,s2,s3,s4,&
            & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
      ENDIF
  ENDDO !iPassQ
ENDDO !iPassP
!not necessary ! 
!reduction afterwards
!!$OMP CRITICAL (distributeKgradBlock)
DO idmat=1,ndmat
   Kcont(idmat) = Kcont(idmat) - tmpKcont(idmat)
ENDDO
!!$OMP END CRITICAL (distributeKgradBlock)
#endif

CONTAINS
subroutine full1(Kcont,DCA,DDA,DCB,DDB,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DCA(n3,n1,ndmat),DDA(n4,n1,ndmat),DCB(n3,n2,ndmat),DDB(n4,n2,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpDB,tmpDA
real(realk),parameter :: D4=4.0E0_realk,D2=2.0E0_realk,D0=0.0E0_realk
!
DO idmat=1,ndmat
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpDA = D0
    tmpDB = D0
    DO iC=1,nC
     tmpDB = tmpDB + DCA(s3+iC,s1+iA,idmat) * CDAB(iC,iD,iA,iB,iPass)
     tmpDA = tmpDA + DCB(s3+iC,s2+iB,idmat) * CDAB(iC,iD,iA,iB,iPass)
    ENDDO
    Kcont(idmat) = Kcont(idmat) + D4 * tmpDA * DDA(s4+iD,s1+iA,idmat)
    Kcont(idmat) = Kcont(idmat) + D4 * tmpDB * DDB(s4+iD,s2+iB,idmat)
   ENDDO
  ENDDO
 ENDDO
ENDDO
end subroutine full1

subroutine full2(Kcont,DCA,DDA,DCB,DDB,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DCA(n3,n1,ndmat),DDA(n4,n1,ndmat),DCB(n3,n2,ndmat),DDB(n4,n2,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpDB,tmpDA
real(realk),parameter :: D4=4.0E0_realk,D2=2.0E0_realk,D0=0.0E0_realk
!
DO idmat=1,ndmat
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpDA = D0
    tmpDB = D0
    DO iC=1,nC
     tmpDB = tmpDB + DCA(s3+iC,s1+iA,idmat) * CDAB(iC,iD,iA,iB,iPass)
     tmpDA = tmpDA + DCB(s3+iC,s2+iB,idmat) * CDAB(iC,iD,iA,iB,iPass)
    ENDDO
    Kcont(idmat) = Kcont(idmat) + D2 * tmpDB * DDB(s4+iD,s2+iB,idmat)
    Kcont(idmat) = Kcont(idmat) + D2 * tmpDA * DDA(s4+iD,s1+iA,idmat)
   ENDDO
  ENDDO
 ENDDO
ENDDO
end subroutine full2

subroutine full3(Kcont,DCA,DDA,DCB,DDB,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DCA(n3,n1,ndmat),DDA(n4,n1,ndmat),DCB(n3,n2,ndmat),DDB(n4,n2,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpDB,tmpDA
real(realk),parameter :: D4=4.0E0_realk,D2=2.0E0_realk,D0=0.0E0_realk
!
DO idmat=1,ndmat
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpDA = D0
    tmpDB = D0
    DO iC=1,nC
     tmpDB = tmpDB + DCA(s3+iC,s1+iA,idmat) * CDAB(iC,iD,iA,iB,iPass)
     tmpDA = tmpDA + DCB(s3+iC,s2+iB,idmat) * CDAB(iC,iD,iA,iB,iPass)
    ENDDO
    Kcont(idmat) = Kcont(idmat) + tmpDB * DDB(s4+iD,s2+iB,idmat)
    Kcont(idmat) = Kcont(idmat) + tmpDA * DDA(s4+iD,s1+iA,idmat)
   ENDDO
  ENDDO
 ENDDO
ENDDO
end subroutine full3

subroutine full4(Kcont,DCA,DDB,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DCA(n3,n1,ndmat),DDB(n4,n2,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpDB,tmpDA
real(realk),parameter :: D2=2.0E0_realk,D0=0.0E0_realk
!
DO idmat=1,ndmat
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpDA = D0
    tmpDB = D0
    DO iC=1,nC
     tmpDB = tmpDB + DCA(s3+iC,s1+iA,idmat) * CDAB(iC,iD,iA,iB,iPass)
    ENDDO
    Kcont(idmat) = Kcont(idmat) + D2 * tmpDB * DDB(s4+iD,s2+iB,idmat)
   ENDDO
  ENDDO
 ENDDO
ENDDO
end subroutine full4

subroutine full5(Kcont,DCA,DDB,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DCA(n3,n1,ndmat),DDB(n4,n2,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpDB(ndmat)
real(realk),parameter :: D0=0.0E0_realk
!
IF(ndmat.EQ.10)THEN
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
     tmpDB = D0
     DO iC=1,nC
        tmpDB(1) = tmpDB(1) + DCA(s3+iC,s1+iA,1) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(2) = tmpDB(2) + DCA(s3+iC,s1+iA,2) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(3) = tmpDB(3) + DCA(s3+iC,s1+iA,3) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(4) = tmpDB(4) + DCA(s3+iC,s1+iA,4) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(5) = tmpDB(5) + DCA(s3+iC,s1+iA,5) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(6) = tmpDB(6) + DCA(s3+iC,s1+iA,6) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(7) = tmpDB(7) + DCA(s3+iC,s1+iA,7) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(8) = tmpDB(8) + DCA(s3+iC,s1+iA,8) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(9) = tmpDB(9) + DCA(s3+iC,s1+iA,9) * CDAB(iC,iD,iA,iB,iPass)
        tmpDB(10) = tmpDB(10) + DCA(s3+iC,s1+iA,10) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
     DO idmat=1,10
        Kcont(idmat) = Kcont(idmat) + tmpDB(idmat) * DDB(s4+iD,s2+iB,idmat)
     ENDDO
   ENDDO
  ENDDO
 ENDDO
ELSE
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
     tmpDB = D0
     DO iC=1,nC
        DO idmat=1,ndmat
           tmpDB(idmat) = tmpDB(idmat) + DCA(s3+iC,s1+iA,idmat) * CDAB(iC,iD,iA,iB,iPass)
        ENDDO
     ENDDO
     DO idmat=1,ndmat
        Kcont(idmat) = Kcont(idmat) + tmpDB(idmat) * DDB(s4+iD,s2+iB,idmat)
     ENDDO    
   ENDDO
  ENDDO
 ENDDO
ENDIF
end subroutine full5

subroutine fullEcont2(Kcont,lAC,lBC,lAD,lBD,rBD,rAD,rBC,rAC,&
     & n1,n2,n3,n4,s1,s2,s3,s4,CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,sym,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: lAC(n1,n3,ndmat),rBD(n2,n4,ndmat)
Real(realk),intent(IN) :: lBC(n2,n3,ndmat),rAD(n1,n4,ndmat)
Real(realk),intent(IN) :: lAD(n1,n4,ndmat),rBC(n2,n3,ndmat)
Real(realk),intent(IN) :: lBD(n2,n4,ndmat),rAC(n1,n3,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
logical,intent(IN)     :: sym
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpBD(ndmat),tmpAD(ndmat),tmpBC(ndmat),tmpAC(ndmat)
real(realk),parameter :: D0=0.0E0_realk,D2=2.0E0_realk
!
IF(.NOT.sym)THEN
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpAD = D0
    tmpBC = D0
    tmpAC = D0
    DO iC=1,nC
     DO idmat=1,ndmat
       tmpBD(idmat) = tmpBD(idmat) + lAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpAD(idmat) = tmpAD(idmat) + lBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpBC(idmat) = tmpBC(idmat) + rBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpAC(idmat) = tmpAC(idmat) + rAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + tmpBD(idmat) * rBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + tmpAD(idmat) * rAD(s1+iA,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + tmpBC(idmat) * lAD(s1+iA,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + tmpAC(idmat) * lBD(s2+iB,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ELSE
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpAD = D0
    tmpBC = D0
    tmpAC = D0
    DO iC=1,nC
     DO idmat=1,ndmat
       tmpBD(idmat) = tmpBD(idmat) + lAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpAD(idmat) = tmpAD(idmat) + lBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpBC(idmat) = tmpBC(idmat) + rBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpAC(idmat) = tmpAC(idmat) + rAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + D2 * tmpBD(idmat) * rBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + D2 * tmpAD(idmat) * rAD(s1+iA,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + D2 * tmpBC(idmat) * lAD(s1+iA,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + D2 * tmpAC(idmat) * lBD(s2+iB,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
end subroutine fullEcont2

subroutine fullEcont3(Kcont,DAC,DBC,DBD,DAD,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,sym,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DAC(n1,n3,ndmat),DBD(n2,n4,ndmat)
Real(realk),intent(IN) :: DBC(n2,n3,ndmat),DAD(n1,n4,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
logical,intent(IN)     :: sym
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpBD(ndmat),tmpAD(ndmat)
real(realk),parameter :: D0=0.0E0_realk,D2=2.0E0_realk
!
IF(.NOT.sym)THEN
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpAD = D0
    DO iC=1,nC
     DO idmat=1,ndmat
        tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        tmpAD(idmat) = tmpAD(idmat) + DBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + tmpAD(idmat) * DAD(s1+iA,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ELSE
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpAD = D0
    DO iC=1,nC
     DO idmat=1,ndmat
        tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        tmpAD(idmat) = tmpAD(idmat) + DBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + D2 * tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + D2 * tmpAD(idmat) * DAD(s1+iA,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
end subroutine fullEcont3

subroutine fullEcont4(Kcont,DAC,DAD,DBD,DBC,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,sym,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DAC(n1,n3,ndmat),DBD(n2,n4,ndmat)
Real(realk),intent(IN) :: DAD(n1,n4,ndmat),DBC(n2,n3,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
logical,intent(IN)     :: sym
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpBD(ndmat),tmpBC(ndmat)
real(realk),parameter :: D0=0.0E0_realk,D2=2.0E0_realk
!
IF(.NOT.sym)THEN
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpBC = D0
    DO iC=1,nC
     DO idmat=1,ndmat
       tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpBC(idmat) = tmpBC(idmat) + DBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + tmpBC(idmat) * DAD(s1+iA,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ELSE
 DO iB=1,nB
  DO iA=1,nA
   DO iD=1,nD
    tmpBD = D0
    tmpBC = D0
    DO iC=1,nC
     DO idmat=1,ndmat
       tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
       tmpBC(idmat) = tmpBC(idmat) + DBC(s2+iB,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
     ENDDO
    ENDDO
    DO idmat=1,ndmat
     Kcont(idmat) = Kcont(idmat) + D2 * tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     Kcont(idmat) = Kcont(idmat) + D2 * tmpBC(idmat) * DAD(s1+iA,s4+iD,idmat)
    ENDDO
   ENDDO
  ENDDO
 ENDDO
ENDIF
end subroutine fullEcont4

subroutine fullEcont5(Kcont,DAC,DBD,n1,n2,n3,n4,s1,s2,s3,s4,&
     & CDAB,nA,nB,nC,nD,iPass,nPasses,ndmat,sym,lupri)
implicit none
Integer,intent(IN)     :: nA,nB,nC,nD,iPass,nPasses,lupri,ndmat
Integer,intent(IN)     :: n1,n2,n3,n4,s1,s2,s3,s4
Real(realk),intent(IN) :: CDAB(nC,nD,nA,nB,nPasses)
Real(realk),intent(IN) :: DAC(n1,n3,ndmat),DBD(n2,n4,ndmat)
Real(realk),intent(INOUT) :: Kcont(ndmat)
logical,intent(IN)     :: sym
!
Integer     :: iA,iB,iC,iD,idmat
Real(realk) :: tmpBD(ndmat)
real(realk),parameter :: D0=0.0E0_realk,D2=2.0E0_realk
!
IF(ndmat.EQ.10)THEN
 IF(.NOT.sym)THEN
  DO iB=1,nB
   DO iA=1,nA
    DO iD=1,nD
     tmpBD = D0
     DO iC=1,nC
        DO idmat=1,10
           tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        ENDDO
     ENDDO
     DO idmat=1,10
        Kcont(idmat) = Kcont(idmat) + tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ELSE
  DO iB=1,nB
   DO iA=1,nA
    DO iD=1,nD
     tmpBD = D0
     DO iC=1,nC
        DO idmat=1,10
           tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        ENDDO
     ENDDO
     DO idmat=1,10
        Kcont(idmat) = Kcont(idmat) + D2*tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     ENDDO
    ENDDO
   ENDDO
  ENDDO
 ENDIF
ELSE
 IF(.NOT.sym)THEN
  DO iB=1,nB
   DO iA=1,nA
    DO iD=1,nD
     tmpBD = D0
     DO iC=1,nC
        DO idmat=1,ndmat
           tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        ENDDO
     ENDDO
     DO idmat=1,ndmat
        Kcont(idmat) = Kcont(idmat) + tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     ENDDO    
    ENDDO
   ENDDO
  ENDDO
 ELSE
  DO iB=1,nB
   DO iA=1,nA
    DO iD=1,nD
     tmpBD = D0
     DO iC=1,nC
        DO idmat=1,ndmat
           tmpBD(idmat) = tmpBD(idmat) + DAC(s1+iA,s3+iC,idmat) * CDAB(iC,iD,iA,iB,iPass)
        ENDDO
     ENDDO
     DO idmat=1,ndmat
        Kcont(idmat) = Kcont(idmat) + D2 * tmpBD(idmat) * DBD(s2+iB,s4+iD,idmat)
     ENDDO    
    ENDDO
   ENDDO
  ENDDO
 ENDIF
ENDIF
end subroutine fullEcont5

END SUBROUTINE distributeKcont

END MODULE thermite_distributeK

