C FILE: DALTON/include/qmnpmm.h
C
      REAL*8  NPCORD,  MMCORD,  NPCHRG,  MMCHRG,
     &        NPFPOL,  NPFCAP,  NPFOMG1, NPFGAM1,
     &        NPFOMG2, NPFGAM2, NPFFAC,
     &        MMFM0,   MMFPOL,
     &        ENSOLQNP, EESOLQNP, ENSOLMNP, EESOLMNP,
     &        ENSOLQMM, EESOLQMM, ENSOLMMM, EESOLMMM
C
      INTEGER TNPBLK,  TMMBLK,  IPRTLVL,
     &        TNPATM,  TMMATM,  NPATOM, NPFTYP,
     &        MMATOM,  MMFTYP,  TNPFF,  TMMFF,
     &        MMMOL,   TPOLATM, MMSKIP
C
      LOGICAL DONPSUB, DOMMSUB, NPMQGAU, MMMQGAU,
     &        MQITER,  CMXPOL,  DONPCAP, DOMMCAP,
     &        DONPPOL, DOMMPOL, NOVDAMP
C
      INTEGER MAXBLK,  MXNPATM, MXMMATM, MXNPFF, MXMMFF
      PARAMETER (MAXBLK = 5)
      PARAMETER (MXNPATM = 10000)
      PARAMETER (MXMMATM = 90000)
      PARAMETER (MXNPFF = 5)
      PARAMETER (MXMMFF = 20)
C
      COMMON /QMNPIN/ NPCORD(3,MXNPATM), MMCORD(3,MXMMATM),     ! real*8
     &                NPCHRG(MAXBLK),    MMCHRG(MAXBLK),
     &                NPFPOL(MXNPFF),    NPFCAP(MXNPFF),
     &                NPFOMG1(MXNPFF),   NPFGAM1(MXNPFF),
     &                NPFOMG2(MXNPFF),   NPFGAM2(MXNPFF),
     &                NPFFAC(MXNPFF),
     &                MMFM0(MXMMFF),     MMFPOL(MXMMFF),
     &                ENSOLQNP, EESOLQNP, ENSOLMNP, EESOLMNP,
     &                ENSOLQMM, EESOLQMM, ENSOLMMM, EESOLMMM,
     &                TNPBLK,  TMMBLK,   IPRTLVL,               ! integer
     &                TNPATM,  TMMATM,   TNPFF,   TMMFF,
     &                NPFTYP(MXNPATM),   TPOLATM, MMFTYP(MXMMATM),
     &                NPATOM(MAXBLK),    MMATOM(MAXBLK),
     &                MMMOL(MXMMATM),    MMSKIP(MXMMATM),
     &                DONPSUB, DOMMSUB,  NPMQGAU, MMMQGAU,      ! logical
     &                MQITER,  CMXPOL,   DONPCAP, DOMMCAP,
     &                DONPPOL, DOMMPOL,  NOVDAMP
C -- end of DALTON/include/qmnpmm.h