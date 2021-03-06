########## Test description ########################
# 24-aug-07 hjaaj: changed from short to long, uses > 8 min on 2GHz pentium
START DESCRIPTION
KEYWORDS: triplet quadratic response dft pcm long
END DESCRIPTION

########## Check list ##############################
START CHECKLIST
enedft
tes
nuc
surf
nucchg
beta
qrlrve2
pcmsol
END CHECKLIST

########## DALTON.INP ##############################
START DALINP
**DALTON INPUT
.RUN RESPONSE
*PCM
.NEWQR
.SOLVNT
WATER
.ICESPH
2
.NESFP
4
.NPCMMT
0
*PCMCAV
.AREATS
0.4D0
.INA
1
2
3
4
.RIN
1.5
1.7
1.2
1.2
**WAVEFUNCTION
.DFT
B3LYP
*SCF INPUT
.THRESH
1.0D-8
**RESPONSE
!.TRPFLG
.MAXRM
200
*QUADRA
!.MAXIT
!100
!.PRINT
!10
.THCLR
1.0D-4
.APROP
XDIPLEN
.BPROP
ZDIPLEN
.CPROP
XDIPLEN
.ASPIN
1
.BSPIN
0
.CSPIN
1
*END OF INPUT
END DALINP

########## MOLECULE.INP ############################
START MOLINP
BASIS
3-21G
Calculation of solvation energy

    3  0 0  X  Y       1.0D-15
       8.     1    3    1    1    1
O1  0.000000  0.000000 -2.2800000
       6.     1    3    1    1    1
C2  0.000000  0.000000  0.0000000
        1.    2    2    1    1
H3   1.78680   0.000000  1.140000
H3  -1.78680   0.000000  1.140000

END MOLINP

########## Reference Output ########################
START REFOUT


         ****************************************************************
         *********** DALTON - An electronic structure program ***********
         ****************************************************************

    This is output from DALTON (Release 2.0 rev. 0, Mar. 2005)

    Celestino Angeli,         University of Ferrara,        Italy      
    Keld L. Bak,              UNI-C,                        Denmark    
    Vebjoern Bakken,          University of Oslo,           Norway     
    Ove Christiansen,         Aarhus University,            Denmark    
    Renzo Cimiraglia,         University of Ferrara,        Italy      
    Sonia Coriani,            University of Trieste,        Italy      
    Paal Dahle,               University of Oslo,           Norway     
    Erik K. Dalskov,          UNI-C,                        Denmark    
    Thomas Enevoldsen,        SDU - Odense University,      Denmark    
    Berta Fernandez,          U. of Santiago de Compostela, Spain      
    Christof Haettig,         Forschungszentrum Karlsruhe,  Germany    
    Kasper Hald,              Aarhus University,            Denmark    
    Asger Halkier,            Aarhus University,            Denmark    
    Hanne Heiberg,            University of Oslo,           Norway     
    Trygve Helgaker,          University of Oslo,           Norway     
    Hinne Hettema,            University of Auckland,       New Zealand
    Hans Joergen Aa. Jensen,  Univ. of Southern Denmark,    Denmark    
    Dan Jonsson,              KTH Stockholm,                Sweden     
    Poul Joergensen,          Aarhus University,            Denmark    
    Sheela Kirpekar,          SDU - Odense University,      Denmark    
    Wim Klopper,              University of Karlsruhe,      Germany    
    Rika Kobayashi,           ANU Supercomputer Facility,   Australia  
    Jakob Kongsted,           Aarhus University,            Denmark    
    Henrik Koch,              University of Trondheim,      Norway     
    Andrea Ligabue,           University of Modena,         Italy      
    Ola B. Lutnaes,           University of Oslo,           Norway     
    Kurt V. Mikkelsen,        University of Copenhagen,     Denmark    
    Patrick Norman,           University of Linkoeping,     Sweden     
    Jeppe Olsen,              Aarhus University,            Denmark    
    Anders Osted,             Copenhagen University,        Denmark    
    Martin J. Packer,         University of Sheffield,      UK         
    Thomas B. Pedersen,       University of Lund,           Sweden     
    Zilvinas Rinkevicius,     KTH Stockholm,                Sweden     
    Elias Rudberg,            KTH Stockholm,                Sweden     
    Torgeir A. Ruden,         University of Oslo,           Norway     
    Kenneth Ruud,             University of Tromsoe,        Norway     
    Pawel Salek,              KTH Stockholm,                Sweden     
    Alfredo Sanchez de Meras, University of Valencia,       Spain      
    Trond Saue,               University of Strasbourg,     France     
    Stephan P. A. Sauer,      University of Copenhagen,     Denmark    
    Bernd Schimmelpfennig,    Forschungszentrum Karlsruhe,  Germany     
    K. O. Sylvester-Hvid,     University of Copenhagen,     Denmark    
    Peter R. Taylor,          University of Warwick,        UK         
    Olav Vahtras,             KTH Stockholm,                Sweden     
    David J. Wilson,          University of Oslo,           Norway     
    Hans Agren,               KTH Stockholm,                Sweden     

 ---------------------------------------------------------------------

     NOTE:
      
     This is an experimental code for the evaluation of molecular
     properties using (MC)SCF and CC wave functions. The authors
     accept no responsibility for the performance of the code or
     for the correctness of the results.
      
     The code (in whole or part) is provided under a licence and
     is not to be reproduced for further distribution without
     the written permission of the authors or their representatives.
      
     See the home page "http://www.kjemi.uio.no/software/dalton"
     for further information.
      
     If results obtained with this code are published,
     an appropriate citation would be:
      
     "Dalton, a molecular electronic structure program, Release 2.0
     (2005), see http://www.kjemi.uio.no/software/dalton/dalton.html"

     Date and time (Linux)  : Tue Nov 13 11:10:04 2007
     Host name              : platina                                 

 <<<<<<<<<< OUTPUT FROM GENERAL INPUT PROCESSING >>>>>>>>>>


 Default print level:        0

    Integral sections will be executed
    "Old" integral transformation used (limited to max 255 basis functions)
    Wave function sections will be executed
    Dynamic molecular property section will be executed

 ** LOOKING UP INTERNALLY STORED DATA FOR SOLVENT = WATER    **
 Optical and physical constants:
 EPS= 78.390; EPSINF=  1.776; RSOLV=  1.385 A; VMOL=  18.070 ML/MOL;
 TCE=2.57000e-04 1/K; STEN= 71.810 DYN/CM;  DSTEN=  0.6500; CMF=  1.2770


     -----------------------------------
     Input for PCM solvation calculation 
     -----------------------------------
     ICOMPCM =       0          SOLVNT=WATER        EPS   = 78.3900     EPSINF=  1.7760
     RSOLV =  1.3850

     ICESPH =       2     NESFP =       4
     OMEGA = 40.0000     RET   =  0.2000     FRO   =  0.7000

     IPRPCM=       0

     NON-EQ = F     NEQRSP =F
 POLYG 60

     INPUT FOR CAVITY DEFINITION 
     ---------------------------
     ATOM         COORDINATES           RADIUS 
     1    0.0000    0.0000    0.0000    1.5000
     2    0.0000    0.0000    0.0000    1.7000
     3    0.0000    0.0000    0.0000    1.2000
     4    0.0000    0.0000    0.0000    1.2000

Starting in Integral Section -



    *************************************************************************
    ****************** Output from HERMIT input processing ******************
    *************************************************************************



    *************************************************************************
    ****************** Output from READIN input processing ******************
    *************************************************************************



  Title Cards
  -----------

  Calculation of solvation energy                                         
                                                                          
  Used basis set file for basis set for elements with Z =   8 :
     "/home/luca/programs/dalton/basis/3-21G"
  Used basis set file for basis set for elements with Z =   6 :
     "/home/luca/programs/dalton/basis/3-21G"
  Used basis set file for basis set for elements with Z =   1 :
     "/home/luca/programs/dalton/basis/3-21G"


                          SYMGRP:Point group information
                          ------------------------------

Point group: C1 

   * Character table

        |  E 
   -----+-----
    A   |   1

   * Direct product table

        | A  
   -----+-----
    A   | A  
 ********SPHERES IN SPHGEN************
 INDEX        X        Y         Z        R
   1    0.0000000000e+00    0.0000000000e+00   -2.2800000000e+00    1.5000000000e+00
   2    0.0000000000e+00    0.0000000000e+00    0.0000000000e+00    1.7000000000e+00
   3    1.7868000000e+00    0.0000000000e+00    1.1400000000e+00    1.2000000000e+00
   4   -1.7868000000e+00    0.0000000000e+00    1.1400000000e+00    1.2000000000e+00


                                 Isotopic Masses
                                 ---------------

                           O1         15.994915
                           C2         12.000000
                           H3          1.007825
                           H3          1.007825

                       Total mass:    30.010565 amu
                       Natural abundance:  98.633 %

 Center-of-mass coordinates (A):    0.000000    0.000000   -1.138618


  Atoms and basis sets
  --------------------

  Number of atom types:     3
  Total number of atoms:    4

  Basis set used is "3-21G" from the basis set library.

  label    atoms   charge   prim   cont     basis
  ----------------------------------------------------------------------
  O1          1    8.0000    15     9      [6s3p|3s2p]                                        
  C2          1    6.0000    15     9      [6s3p|3s2p]                                        
  H3          2    1.0000     3     2      [3s|2s]                                            
  ----------------------------------------------------------------------
  total:      4   16.0000    36    22
  ----------------------------------------------------------------------

  Threshold for integrals:  1.00e-15


  Cartesian Coordinates (a.u.)
  ----------------------------

  Total number of coordinates:   12
  O1      :    1  x   0.0000000000   2  y   0.0000000000   3  z  -2.2800000000
  C2      :    4  x   0.0000000000   5  y   0.0000000000   6  z   0.0000000000
  H3      :    7  x   1.7868000000   8  y   0.0000000000   9  z   1.1400000000
  H3      :   10  x  -1.7868000000  11  y   0.0000000000  12  z   1.1400000000


   Interatomic separations (in Angstrom):
   --------------------------------------

            O1          C2          H3          H3    
            ------      ------      ------      ------
 O1    :    0.000000
 C2    :    1.206524    0.000000
 H3    :    2.041901    1.121588    0.000000
 H3    :    2.041901    1.121588    1.891068    0.000000


  Max interatomic separation is    2.0419 Angstrom
  between atoms "H3    " and "O1    ".


  Bond distances (Angstrom):
  --------------------------

                  atom 1     atom 2       distance
                  ------     ------       --------
  bond distance:  C2         O1           1.206524
  bond distance:  H3         C2           1.121588
  bond distance:  H3         C2           1.121588


  Bond angles (degrees):
  ----------------------

                  atom 1     atom 2     atom 3         angle
                  ------     ------     ------         -----
  bond angle:     O1         C2         H3           122.538
  bond angle:     O1         C2         H3           122.538
  bond angle:     H3         C2         H3           114.923




 Principal moments of inertia (u*A**2) and principal axes
 --------------------------------------------------------

   IA       1.802060          0.000000    0.000000    1.000000
   IB      13.122217          1.000000    0.000000    0.000000
   IC      14.924277          0.000000    1.000000    0.000000


 Rotational constants
 --------------------

 The molecule is planar.

               A                   B                   C

         280445.1440          38513.2324          33862.8793 MHz
            9.354643            1.284663            1.129544 cm-1


  Nuclear repulsion energy :   31.140735918780


     ************************************************************************
     ************************** Output from HERINT **************************
     ************************************************************************


 Number of two-electron integrals written:       15102 ( 47.0% )
 Megabytes written:                              0.179



 MEMORY USED TO GENERATE CAVITY =    432042


 Total number of spheres =    4
 Sphere             Center  (X,Y,Z) (A)               Radius (A)      Area (A^2)
   1    0.000000000    0.000000000   -1.206524035    1.800000000   22.860798949
   2    0.000000000    0.000000000    0.000000000    2.040000000   24.717903724
   3    0.945533836    0.000000000    0.603262017    1.440000000    9.680866932
   4   -0.945533836    0.000000000    0.603262017    1.440000000    9.680866932

 Total number of tesserae =     256
 Surface area =   66.94043654 (A^2)    Cavity volume =   48.54512116 (A^3)

          THE SOLUTE IS ENCLOSED IN ONE CAVITY

 ..... DONE GENERATION CAVITY .....

 >>> Time used in PEDRAM is   0.14 seconds


  ..... DONE GENERATING -Q-  MATRIX .....

 >>> Time used in Q-MAT is   0.26 seconds

 >>>> Total CPU  time used in HERMIT:   0.40 seconds
 >>>> Total wall time used in HERMIT:   1.00 seconds

- End of Integral Section


Starting in Wave Function Section -


 *** Output from Huckel module :

     Using EWMO model:          T
     Using EHT  model:          F
     Number of Huckel orbitals each symmetry:   12

 EWMO - Energy Weighted Maximum Overlap - is a Huckel type method,
        which normally is better than Extended Huckel Theory.
 Reference: Linderberg and Ohrn, Propagators in Quantum Chemistry (Wiley, 1973)

 Huckel EWMO eigenvalues for symmetry :  1
          -20.684793     -11.351633      -1.627151      -1.046455      -0.808323
           -0.702554      -0.608518      -0.491424      -0.320546      -0.162219
           -0.133092      -0.114392

 **********************************************************************
 *SIRIUS* a direct, restricted step, second order MCSCF program       *
 **********************************************************************

 
     Date and time (Linux)  : Tue Nov 13 11:10:05 2007
     Host name              : platina                                 

 Title lines from integral program:
     Calculation of solvation energy                                         
                                                                             

 Print level on unit LUPRI =   2 is   0
 Print level on unit LUW4  =   2 is   5

     Restricted, closed shell Kohn-Sham calculation.


     Time-dependent Kohn-Sham calculation (random phase approximation).


 Initial molecular orbitals are obtained according to
 ".MOSTART EWMO  " input option.

     Wave function specification
     ============================
     Number of closed shell electrons         16
     Number of electrons in active shells      0
     Total charge of the molecule              0

     Number of active orbitals                 0
     Total number of orbitals                 22

     Spin multiplicity                         1
     Total number of symmetries                1
     Reference state symmetry                  1
 
     This is a DFT calculation of type: B3LYP
 Weighted mixed functional:
               HF exchange:    0.20000
                       VWN:    0.19000
                       LYP:    0.81000
                     Becke:    0.72000
                    Slater:    0.80000

     Orbital specifications
     ======================
     Abelian symmetry species           1
                                       --
     Total number of orbitals          22
     Number of basis functions         22

      ** Automatic occupation of RKS orbitals **
      -- Initial occupation of symmetries is determined from Huckel guess.                    
      -- Initial occupation of symmetries is : --

     Occupied SCF orbitals              8

     Maximum number of Fock   iterations      0
     Maximum number of DIIS   iterations     60
     Maximum number of QC-SCF iterations     60
     Threshold for SCF convergence     1.00e-08

          -------------------------------------
          ---- POLARISABLE CONTINUUM MODEL ----
          ----      UNIVERSITY OF PISA     ----
          -------------------------------------

 ESTIMATE OF NUCLEAR CHARGE       15.96948
 NUCLEAR APPARENT CHARGE -15.79043
 THEORETICAL -15.79589 NOT RENORMALIZED

 ..... DONE WITH INDUCED NUCLEAR CHARGES .....


 >>>>> DIIS optimization of Hartree-Fock <<<<<

 C1-DIIS algorithm; max error vectors =   10

 Automatic occupation of symmetries with  16 electrons.

 Iter     Total energy      Solvation energy  Error norm  Delta(E)    HF occupation
 ----------------------------------------------------------------------------------
 Radial Quadrature : LMG scheme
 Space partitioning: Original Becke partitioning
 Radial integration threshold: 1e-13
 Angular polynomials in range [15 35]
 Atom:    1*1 points=18822 compressed from 18912 ( 96 radial)
 Atom:    2*1 points=19284 compressed from 19284 ( 96 radial)
 Atom:    3*1 points=18294 compressed from 18406 ( 77 radial)
 Atom:    4*1 points=18294 compressed from 18406 ( 77 radial)
 Number of grid points:    74694 Grid generation time:       0.2 s
K-S electrons/energy :   15.99999884968284  -11.72593537636938 err:-.12e-05
   1  -113.390743664     -1.932687778486e-02   2.60e+00  -1.13e+02    8
K-S electrons/energy :   15.99999897365769  -11.76206131011593 err:-.10e-05
   2  -112.933540449     -1.814273124713e-02   4.09e+00   4.57e-01    8
K-S electrons/energy :   15.99999890985142  -11.91058111601288 err:-.11e-05
   3  -113.776960584     -1.245870869010e-02   8.22e-01  -8.43e-01    8
K-S electrons/energy :   15.99999891568205  -11.76339838104095 err:-.11e-05
   4  -113.803503574     -4.704649929567e-03   2.05e-01  -2.65e-02    8
K-S electrons/energy :   15.99999891970872  -11.80178230430858 err:-.11e-05
   5  -113.805702698     -5.470897573911e-03   1.47e-02  -2.20e-03    8
K-S electrons/energy :   15.99999891944529  -11.79894842270340 err:-.11e-05
   6  -113.805714870     -5.331001266315e-03   2.52e-03  -1.22e-05    8
K-S electrons/energy :   15.99999891941810  -11.79923578321432 err:-.11e-05
   7  -113.805715192     -5.353798517367e-03   7.98e-05  -3.22e-07    8
K-S electrons/energy :   15.99999891941561  -11.79924709651286 err:-.11e-05
   8  -113.805715192     -5.354104904913e-03   4.06e-06  -3.36e-10    8
K-S electrons/energy :   15.99999891941548  -11.79924704272557 err:-.11e-05
   9  -113.805715192     -5.354120794930e-03   8.49e-07  -8.95e-13    8
K-S electrons/energy :   15.99999891941544  -11.79924709765325 err:-.11e-05
  10  -113.805715192     -5.354126191187e-03   4.43e-08   2.02e-13    8
K-S electrons/energy :   15.99999891941543  -11.79924710198415 err:-.11e-05
  11  -113.805715192     -5.354126511704e-03   4.02e-10  -2.02e-13    8
 DIIS converged in  11 iterations !


 *** SCF orbital energy analysis ***
    (incl. solvent contribution)

 Only the five lowest virtual orbital energies printed in each symmetry.

 Number of electrons :   16
 Orbital occupations :    8

 Sym       Kohn-Sham orbital energies

  1    -19.05344555   -10.21721710    -1.07462041    -0.61727623    -0.48794101
        -0.43424520    -0.39564127    -0.25301269    -0.02631012     0.13403608
         0.21918798     0.28594713     0.68545946

    E(LUMO) :    -0.02631012 au (symmetry 1)
  - E(HOMO) :    -0.25301269 au (symmetry 1)
  ------------------------------------------
    gap     :     0.22670257 au

 >>> Writing SIRIFC interface file <<<


                    >>> FINAL RESULTS FROM SIRIUS <<<

     Spin multiplicity:           1
     Spatial symmetry:            1
     Total charge of molecule:    0

     SOLVATION MODEL: polarizable continuum model (PCM),
          dielectric constant =   78.390000

     Final DFT energy:           -113.805715191949
     Nuclear repulsion:            31.140735918780
     Electronic energy:          -144.941096984217

     Final gradient norm:           0.000000000402

 
     Date and time (Linux)  : Tue Nov 13 11:10:50 2007
     Host name              : platina                                 

     Molecular orbitals for symmetry species   1

 Orbital           1        2        3        4        5        6        7
   1 O1  :1s    -0.9825  -0.0003   0.2112   0.0948   0.0000  -0.1001   0.0000
   2 O1  :1s    -0.1051  -0.0006  -0.2042  -0.0917   0.0000   0.0836   0.0000
   3 O1  :1s     0.0530   0.0013  -0.6363  -0.3615   0.0000   0.4119   0.0000
   4 O1  :2px    0.0000   0.0000   0.0000   0.0000   0.2459   0.0000   0.0000
   5 O1  :2py    0.0000   0.0000   0.0000   0.0000   0.0000   0.0000  -0.4097
   6 O1  :2pz   -0.0045   0.0012  -0.1565   0.0766   0.0000  -0.4247   0.0000
   7 O1  :2px    0.0000   0.0000   0.0000   0.0000   0.2105   0.0000   0.0000
   8 O1  :2py    0.0000   0.0000   0.0000   0.0000   0.0000   0.0000  -0.4154
   9 O1  :2pz    0.0142   0.0056  -0.1389   0.0603   0.0000  -0.4039   0.0000
  10 C2  :1s    -0.0002  -0.9850   0.1229  -0.1737   0.0000   0.0295   0.0000
  11 C2  :1s    -0.0005  -0.1029  -0.1348   0.1982   0.0000  -0.0613   0.0000
  12 C2  :1s    -0.0194   0.0493  -0.1382   0.5180   0.0000   0.0169   0.0000
  13 C2  :2px    0.0000   0.0000   0.0000   0.0000   0.3839   0.0000   0.0000
  14 C2  :2py    0.0000   0.0000   0.0000   0.0000   0.0000   0.0000  -0.3142
  15 C2  :2pz    0.0025   0.0018   0.1688   0.1804   0.0000   0.3285   0.0000
  16 C2  :2px    0.0000   0.0000   0.0000   0.0000   0.2982   0.0000   0.0000
  17 C2  :2py    0.0000   0.0000   0.0000   0.0000   0.0000   0.0000  -0.2967
  18 C2  :2pz    0.0153   0.0087  -0.0390   0.1285   0.0000   0.0700   0.0000
  19 H3  :1s     0.0008   0.0022  -0.0229   0.1682   0.1724   0.0749   0.0000
  20 H3  :1s    -0.0006  -0.0141   0.0178   0.0602   0.1053   0.0926   0.0000
  21 H3  :1s     0.0008   0.0022  -0.0229   0.1682  -0.1724   0.0749   0.0000
  22 H3  :1s    -0.0006  -0.0141   0.0178   0.0602  -0.1053   0.0926   0.0000

 Orbital           8        9       10       11       12       13
   1 O1  :1s     0.0000   0.0000  -0.0074   0.0000  -0.1268   0.0000
   2 O1  :1s     0.0000   0.0000   0.0145   0.0000   0.0531   0.0000
   3 O1  :1s     0.0000   0.0000   0.0109   0.0000   1.5491   0.0000
   4 O1  :2px    0.4699   0.0000   0.0000  -0.1756   0.0000   0.0000
   5 O1  :2py    0.0000   0.3719   0.0000   0.0000   0.0000  -0.0336
   6 O1  :2pz    0.0000   0.0000   0.0746   0.0000   0.2148   0.0000
   7 O1  :2px    0.5242   0.0000   0.0000  -0.3602   0.0000   0.0000
   8 O1  :2py    0.0000   0.5230   0.0000   0.0000   0.0000  -0.1389
   9 O1  :2pz    0.0000   0.0000   0.1044   0.0000   0.7275   0.0000
  10 C2  :1s     0.0000   0.0000   0.1509   0.0000   0.0716   0.0000
  11 C2  :1s     0.0000   0.0000  -0.1034   0.0000   0.0185   0.0000
  12 C2  :1s     0.0000   0.0000  -1.7360   0.0000  -1.0514   0.0000
  13 C2  :2px   -0.1477   0.0000   0.0000   0.4826   0.0000   0.0000
  14 C2  :2py    0.0000  -0.4358   0.0000   0.0000   0.0000  -1.0498
  15 C2  :2pz    0.0000   0.0000  -0.2084   0.0000   0.1403   0.0000
  16 C2  :2px    0.0382   0.0000   0.0000   1.2598   0.0000   0.0000
  17 C2  :2py    0.0000  -0.6094   0.0000   0.0000   0.0000   1.0638
  18 C2  :2pz    0.0000   0.0000  -0.6168   0.0000   1.6434   0.0000
  19 H3  :1s    -0.1805   0.0000   0.1007  -0.0359   0.0198   0.0000
  20 H3  :1s    -0.3102   0.0000   1.2341  -1.3562  -0.2157   0.0000
  21 H3  :1s     0.1805   0.0000   0.1007   0.0359   0.0198   0.0000
  22 H3  :1s     0.3102   0.0000   1.2341   1.3562  -0.2157   0.0000



 >>>> Total CPU  time used in SIRIUS :     43.63 seconds
 >>>> Total wall time used in SIRIUS :     45.00 seconds

 
     Date and time (Linux)  : Tue Nov 13 11:10:50 2007
     Host name              : platina                                 

- End of Wave Function Section



  This is output from RESPONSE  -  an MCSCF and SOPPA response property program
 ------------------------------------------------------------------------------



 <<<<<<<<<< OUTPUT FROM RESPONSE INPUT PROCESSING >>>>>>>>>>




 CHANGES OF DEFAULTS FOR RSPINP:
 -------------------------------


 USE FOCK TYPE DECOUPLING OF THE TWO-ELECTRON DENSITY MATRIX :
 ADD DV*(FC+FV) INSTEAD OF DV*FC TO E[2] APPROXIMATE ORBITAL DIAGONAL
  AVDIA = T


 Quadratic Response calculation
 ------------------------------

 First hyperpolarizability calculation : HYPCAL= T

 Spin of operator A , ISPINA=    1
 Spin of operator B , ISPINB=    0
 Spin of operator C , ISPINC=    1

  1 B-frequencies  0.000000e+00
  1 C-frequencies  0.000000e+00

 Print level                                    : IPRHYP =   2
 Maximum number of iterations in lin.rsp. solver: MAXITL =  60
 Threshold for convergence of linear resp. eq.s : THCLR  = 1.000e-04
 Maximum iterations in optimal orbital algorithm: MAXITO =   5
 Direct one-index transformation                : DIROIT= T

    1 A OPERATORS OF SYMMETRY NO:    1 AND LABELS:

          XDIPLEN 

    1 B OPERATORS OF SYMMETRY NO:    1 AND LABELS:

          ZDIPLEN 

    1 C OPERATORS OF SYMMETRY NO:    1 AND LABELS:

          XDIPLEN 


   SCF energy         :     -113.805715191948835
 -- inactive part     :     -144.941096984216784
 -- nuclear repulsion :       31.140735918779651


 Linear response calculations for quadratic response
 - singlet property operator of symmetry    1


 Perturbation symmetry.     KSYMOP:       1
 Perturbation spin symmetry.TRPLET:       F
 Orbital variables.         KZWOPT:     112
 Configuration variables.   KZCONF:       0
 Total number of variables. KZVAR :     112


 QRLRVE -- linear response calculation for symmetry  1
 QRLRVE -- operator label : ZDIPLEN 
 QRLRVE -- frequencies :  0.000000



 <<<  SOLVING SETS OF LINEAR EQUATIONS FOR LINEAR RESPONSE PROPERTIES >>>

 Operator symmetry =  1; triplet =   F

 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.4 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.4 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.4 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s

 *** THE REQUESTED    1 SOLUTION VECTORS CONVERGED

 Convergence of RSP solution vectors, threshold = 1.00e-04
 ---------------------------------------------------------------
 (dimension of paired reduced space:   12)
 RSP solution vector no.    1; norm of residual   8.97e-06

 *** RSPCTL MICROITERATIONS CONVERGED

 QRLRVE: SINGLET SOLUTION   LABEL   ZDIPLEN     FREQUENCY   0.000000e+00
 SYMMETRY    1

@QRLRVE:  << ZDIPLEN  ; ZDIPLEN  >> (   0.00000):     19.7071042516    


 Linear response calculations for quadratic response
 - triplet property operator(s) of symmetry    1


 Perturbation symmetry.     KSYMOP:       1
 Perturbation spin symmetry.TRPLET:       T
 Orbital variables.         KZWOPT:     112
 Configuration variables.   KZCONF:       0
 Total number of variables. KZVAR :     112


 QRTRVE -- linear response calculation for symmetry  1
 QRTRVE -- operator label : XDIPLEN 
 QRTRVE -- frequencies :  0.000000



 <<<  SOLVING SETS OF LINEAR EQUATIONS FOR LINEAR RESPONSE PROPERTIES >>>

 Operator symmetry =  1; triplet =   T

 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s
 Electrons: 15.999999(-1.08e-06): LR-DFT*1 evaluation time:       1.5 s

 *** THE REQUESTED    1 SOLUTION VECTORS CONVERGED

 Convergence of RSP solution vectors, threshold = 1.00e-04
 ---------------------------------------------------------------
 (dimension of paired reduced space:    8)
 RSP solution vector no.    1; norm of residual   5.53e-05

 *** RSPCTL MICROITERATIONS CONVERGED
 
 ======================================================================
 >>>>>>>>    L I N E A R   R E S P O N S E   F U N C T I O N   <<<<<<<<
 ======================================================================

 The -<<A;B>>(omega_b) functions from vectors generated
 in a *QUADRA calculation of <<A;B,C>>(omega_b,omega_c)

 Note: the accuracy of off-diagonal elements will be linear
 in the convergence threshold THCLR =  1.00e-04

 All zero because spin symmetry of A and B is different.
 ISPINA and ISPINB :    1   0


  Results from quadratic response calculation
 --------------------------------------------

 DFT-QR computed in a linearly-scaling fashion.

 Electrons: 15.999999(-1.08e-06): QR-DFT/b evaluation time:       2.1 s
 INITIAL ETRS

              Column   1
       3      0.03089455
       7     -0.00250249
       9      0.00113463
      13      0.00265168
      17     -0.07480681
      21     -0.02709534
      23      0.02422972
      27     -0.00392149
      31      0.10432069
      35     -0.09261715
      37      0.02278418
      41     -0.03714543
      45      1.07921889
      49      0.08298507
      51     -0.47021722
      55     -0.17741179
      58     -3.60890517
      60     -0.15194546
      62     -0.37545159
      64     -0.75238867
      66     -0.46604068
      68      0.33440397
      70      0.35545751
      73     -1.83199664
      77      0.03788409
      79     -0.28699225
      83     -0.69649764
     100     -5.36615079
     102     -1.18958976
     104     -1.13980019
     106      2.03284841
     108      0.23887105
     110     -0.62726020
     112      0.47805642
     115     -0.03089455
     119      0.00250249
     121     -0.00113463
     125     -0.00265168
     129      0.07480681
     133      0.02709534
     135     -0.02422972
     139      0.00392149
     143     -0.10432069
     147      0.09261715
     149     -0.02278418
     153      0.03714543
     157     -1.07921889
     161     -0.08298507
     163      0.47021722
     167      0.17741179
     170      3.60890517
     172      0.15194546
     174      0.37545159
     176      0.75238867
     178      0.46604068
     180     -0.33440397
     182     -0.35545751
     185      1.83199664
     189     -0.03788409
     191      0.28699225
     195      0.69649764
     212      5.36615079
     214      1.18958976
     216      1.13980019
     218     -2.03284841
     220     -0.23887105
     222      0.62726020
     224     -0.47805642

     Zero matrix.

     Zero matrix.

     Zero matrix.
 Norm of TOPGET   0.
 Vector in PCM1GR
 (Reference state)


 Density matrix in PCP1GR


 One electron matrix in PCM1GR

     Zero matrix.

     Zero matrix.

     Zero matrix.

     Zero matrix.
 Norm of TOPGET   0.
 Vector in PCM1GR
 (Reference state)


 Density matrix in PCP1GR


 One electron matrix in PCM1GR

     Zero matrix.

              Column   1
       1      0.01261494
       2      0.01995715
       3      0.01966672
       4      0.01282225
       5      0.00610066
       6      0.00179209
       7      0.00610183
       8      0.02443920
       9      0.04519287
      10      0.04615815
      11      0.04199823
      12      0.06341571
      13      0.04541712
      14      0.01898006
      15      0.03635782
      16      0.03815825
      17      0.02072674
      18      0.04011221
      19      0.05487995
      20      0.05705445
      21      0.03418446
      22      0.05113864
      23      0.03731864
      24      0.01261494
      25      0.01995715
      26      0.01966672
      27      0.01282225
      28      0.00610066
      29      0.00179209
      30      0.00610183
      31      0.02443920
      32      0.04519287
      33      0.04615815
      34      0.04199823
      35      0.06341571
      36      0.04541712
      37      0.01898006
      38      0.03635782
      39      0.03815825
      40      0.02072674
      41      0.04011221
      42      0.05487995
      43      0.05705445
      44      0.03418446
      45      0.05113864
      46      0.03731864
      47      0.01261494
      48      0.01995715
      49      0.01966672
      50      0.01282225
      51      0.00610066
      52      0.00179209
      53      0.00610183
      54      0.02443920
      55      0.04519287
      56      0.04615815
      57      0.04199823
      58      0.06341571
      59      0.04541712
      60      0.01898006
      61      0.03635782
      62      0.03815825
      63      0.02072674
      64      0.04011221
      65      0.05487995
      66      0.05705445
      67      0.03418446
      68      0.05113864
      69      0.03731864
      70      0.01261494
      71      0.01995715
      72      0.01966672
      73      0.01282225
      74      0.00610066
      75      0.00179209
      76      0.00610183
      77      0.02443920
      78      0.04519287
      79      0.04615815
      80      0.04199823
      81      0.06341571
      82      0.04541712
      83      0.01898006
      84      0.03635782
      85      0.03815825
      86      0.02072674
      87      0.04011221
      88      0.05487995
      89      0.05705445
      90      0.03418446
      91      0.05113864
      92      0.03731864
      93     -0.02798926
      94     -0.04321572
      95     -0.02092064
      96     -0.02907586
      97     -0.00520739
      98     -0.01744252
      99     -0.00945930
     100     -0.02856743
     101     -0.04912405
     102     -0.02404424
     103     -0.01989773
     104      0.01616100
     105      0.01713107
     106      0.01333707
     107      0.00036177
     108     -0.00220007
     109     -0.00304561
     110     -0.00457665
     111      0.00397887
     112      0.00359732
     113      0.00619133
     114      0.01240600
     115      0.00197435
     116     -0.02798926
     117     -0.04321572
     118     -0.02092064
     119     -0.02907586
     120     -0.00520739
     121     -0.01744252
     122     -0.00945930
     123     -0.02856743
     124     -0.04912405
     125     -0.02404424
     126     -0.01989773
     127      0.01616100
     128      0.01713107
     129      0.01333707
     130      0.00036177
     131     -0.00220007
     132     -0.00304561
     133     -0.00457665
     134      0.00397887
     135      0.00359732
     136      0.00619133
     137      0.01240600
     138      0.00197435
     139     -0.02798926
     140     -0.04321572
     141     -0.02092064
     142     -0.02907586
     143     -0.00520739
     144     -0.01744252
     145     -0.00945930
     146     -0.02856743
     147     -0.04912405
     148     -0.02404424
     149     -0.01989773
     150      0.01616100
     151      0.01713107
     152      0.01333707
     153      0.00036177
     154     -0.00220007
     155     -0.00304561
     156     -0.00457665
     157      0.00397887
     158      0.00359732
     159      0.00619133
     160      0.01240600
     161      0.00197435
     162     -0.02798926
     163     -0.04321572
     164     -0.02092064
     165     -0.02907586
     166     -0.00520739
     167     -0.01744252
     168     -0.00945930
     169     -0.02856743
     170     -0.04912405
     171     -0.02404424
     172     -0.01989773
     173      0.01616100
     174      0.01713107
     175      0.01333707
     176      0.00036177
     177     -0.00220007
     178     -0.00304561
     179     -0.00457665
     180      0.00397887
     181      0.00359732
     182      0.00619133
     183      0.01240600
     184      0.00197435
     185     -0.02995232
     186     -0.05129458
     187     -0.04906401
     188     -0.02566727
     189     -0.04266925
     190     -0.01017603
     191     -0.05029901
     192     -0.04585284
     193     -0.04370547
     194     -0.00679937
     195     -0.02101579
     196     -0.03191928
     197     -0.00302748
     198     -0.02737835
     199     -0.00624515
     200     -0.02982551
     201     -0.02607511
     202     -0.01570119
     203     -0.02995232
     204     -0.05129458
     205     -0.04906401
     206     -0.02566727
     207     -0.04266925
     208     -0.01017603
     209     -0.05029901
     210     -0.04585284
     211     -0.04370547
     212     -0.00679937
     213     -0.02101579
     214     -0.03191928
     215     -0.00302748
     216     -0.02737835
     217     -0.00624515
     218     -0.02982551
     219     -0.02607511
     220     -0.01570119
     221     -0.02982551
     222     -0.02607511
     223     -0.01570119
     224     -0.02995232
     225     -0.05129458
     226     -0.04906401
     227     -0.02566727
     228     -0.04266925
     229     -0.01017603
     230     -0.05029901
     231     -0.04585284
     232     -0.04370547
     233     -0.00679937
     234     -0.02101579
     235     -0.03191928
     236     -0.00302748
     237     -0.02737835
     238     -0.00624515
     239     -0.02982551
     240     -0.02607511
     241     -0.01570119
     242     -0.02995232
     243     -0.05129458
     244     -0.04906401
     245     -0.02566727
     246     -0.04266925
     247     -0.01017603
     248     -0.05029901
     249     -0.04585284
     250     -0.04370547
     251     -0.00679937
     252     -0.02101579
     253     -0.03191928
     254     -0.00302748
     255     -0.02737835
     256     -0.00624515

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.38399543    0.00001262   -0.00367229    0.00148042    0.00000000
       2      0.00001262   -0.07927170    0.00652078    0.00612750    0.00000000
       3     -0.00367229    0.00652078    0.24744947    0.12082328    0.00000000
       4      0.00148042    0.00612750    0.12082328   -0.14950728    0.00000000
       5      0.00000000    0.00000000    0.00000000    0.00000000   -0.03538880
       6     -0.00950050    0.00950871   -0.08324318   -0.24150305    0.00000000
       8      0.00000000    0.00000000    0.00000000    0.00000000    0.26758863
      10      0.00116963   -0.00529539   -0.00369428   -0.04347492    0.00000000
      11      0.00000000    0.00000000    0.00000000    0.00000000    0.04117487
      12      0.00233251    0.00309862   -0.02619097   -0.09048662    0.00000000
      14     -0.00689663   -0.02060888    0.05689686   -0.04258008    0.00000000
      15      0.00000000    0.00000000    0.00000000    0.00000000    0.03453046
      16      0.00207244    0.01206544   -0.02400769    0.01564343    0.00000000
      17      0.00000000    0.00000000    0.00000000    0.00000000    0.02256624
      18     -0.00600839    0.00451046    0.01791408    0.02738323    0.00000000
      20     -0.01264068    0.00103844    0.01938104    0.03072573    0.00000000
      21      0.00000000    0.00000000    0.00000000    0.00000000   -0.01371178
      22      0.00378942   -0.00193949   -0.00100984    0.00953563    0.00000000

              Column   6    Column   7    Column   8    Column   9    Column  10
       1     -0.00950050    0.00000000    0.00000000    0.00000000    0.00116963
       2      0.00950871    0.00000000    0.00000000    0.00000000   -0.00529539
       3     -0.08324318    0.00000000    0.00000000    0.00000000   -0.00369428
       4     -0.24150305    0.00000000    0.00000000    0.00000000   -0.04347492
       5      0.00000000    0.00000000    0.26758863    0.00000000    0.00000000
       6      0.31887334    0.00000000    0.00000000    0.00000000   -0.06664946
       7      0.00000000    0.21847064    0.00000000   -0.23715891    0.00000000
       8      0.00000000    0.00000000    0.16955310    0.00000000    0.00000000
       9      0.00000000   -0.23715891    0.00000000    0.07392392    0.00000000
      10     -0.06664946    0.00000000    0.00000000    0.00000000   -0.33254662
      11      0.00000000    0.00000000   -0.20728535    0.00000000    0.00000000
      12     -0.13213199    0.00000000    0.00000000    0.00000000   -0.01867082
      13      0.00000000   -0.00635711    0.00000000    0.03350545    0.00000000
      14      0.08252099    0.00000000    0.00000000    0.00000000   -0.07274581
      15      0.00000000    0.00000000   -0.05899181    0.00000000    0.00000000
      16     -0.05028357    0.00000000    0.00000000    0.00000000   -0.00636913
      17      0.00000000    0.00000000   -0.03879182    0.00000000    0.00000000
      18      0.02471562    0.00000000    0.00000000    0.00000000   -0.06926374
      19      0.00000000    0.04089218    0.00000000    0.03866927    0.00000000
      20     -0.05749178    0.00000000    0.00000000    0.00000000    0.01224888
      21      0.00000000    0.00000000   -0.04014020    0.00000000    0.00000000
      22      0.01479528    0.00000000    0.00000000    0.00000000    0.02218754

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00000000    0.00233251    0.00000000   -0.00689663    0.00000000
       2      0.00000000    0.00309862    0.00000000   -0.02060888    0.00000000
       3      0.00000000   -0.02619097    0.00000000    0.05689686    0.00000000
       4      0.00000000   -0.09048662    0.00000000   -0.04258008    0.00000000
       5      0.04117487    0.00000000    0.00000000    0.00000000    0.03453046
       6      0.00000000   -0.13213199    0.00000000    0.08252099    0.00000000
       7      0.00000000    0.00000000   -0.00635711    0.00000000    0.00000000
       8     -0.20728535    0.00000000    0.00000000    0.00000000   -0.05899181
       9      0.00000000    0.00000000    0.03350545    0.00000000    0.00000000
      10      0.00000000   -0.01867082    0.00000000   -0.07274581    0.00000000
      11     -0.26251592    0.00000000    0.00000000    0.00000000    0.02715696
      12      0.00000000    0.01177485    0.00000000   -0.12458861    0.00000000
      13      0.00000000    0.00000000   -0.10143271    0.00000000    0.00000000
      14      0.00000000   -0.12458861    0.00000000   -0.08003909    0.00000000
      15      0.02715696    0.00000000    0.00000000    0.00000000    0.01000516
      16      0.00000000   -0.04821019    0.00000000   -0.17693677    0.00000000
      17      0.12995982    0.00000000    0.00000000    0.00000000   -0.02235754
      18      0.00000000    0.07887646    0.00000000    0.11603539    0.00000000
      19      0.00000000    0.00000000   -0.06996052    0.00000000    0.00000000
      20      0.00000000    0.05014724    0.00000000   -0.02518180    0.00000000
      21     -0.02338388    0.00000000    0.00000000    0.00000000   -0.12021659
      22      0.00000000    0.11874177    0.00000000    0.02772008    0.00000000

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00207244    0.00000000   -0.00600839    0.00000000   -0.01264068
       2      0.01206544    0.00000000    0.00451046    0.00000000    0.00103844
       3     -0.02400769    0.00000000    0.01791408    0.00000000    0.01938104
       4      0.01564343    0.00000000    0.02738323    0.00000000    0.03072573
       5      0.00000000    0.02256624    0.00000000    0.00000000    0.00000000
       6     -0.05028357    0.00000000    0.02471562    0.00000000   -0.05749178
       7      0.00000000    0.00000000    0.00000000    0.04089218    0.00000000
       8      0.00000000   -0.03879182    0.00000000    0.00000000    0.00000000
       9      0.00000000    0.00000000    0.00000000    0.03866927    0.00000000
      10     -0.00636913    0.00000000   -0.06926374    0.00000000    0.01224888
      11      0.00000000    0.12995982    0.00000000    0.00000000    0.00000000
      12     -0.04821019    0.00000000    0.07887646    0.00000000    0.05014724
      13      0.00000000    0.00000000    0.00000000   -0.06996052    0.00000000
      14     -0.17693677    0.00000000    0.11603539    0.00000000   -0.02518180
      15      0.00000000   -0.02235754    0.00000000    0.00000000    0.00000000
      16     -0.24496508    0.00000000   -0.07834213    0.00000000    0.05502041
      17      0.00000000   -0.30382523    0.00000000    0.00000000    0.00000000
      18     -0.07834213    0.00000000   -0.11665323    0.00000000    0.18042448
      19      0.00000000    0.00000000    0.00000000    0.38887386    0.00000000
      20      0.05502041    0.00000000    0.18042448    0.00000000    0.45129352
      21      0.00000000   -0.05229773    0.00000000    0.00000000    0.00000000
      22     -0.00819519    0.00000000    0.03421551    0.00000000    0.05744933

              Column  21    Column  22
       1      0.00000000    0.00378942
       2      0.00000000   -0.00193949
       3      0.00000000   -0.00100984
       4      0.00000000    0.00953563
       5     -0.01371178    0.00000000
       6      0.00000000    0.01479528
       8     -0.04014020    0.00000000
      10      0.00000000    0.02218754
      11     -0.02338388    0.00000000
      12      0.00000000    0.11874177
      14      0.00000000    0.02772008
      15     -0.12021659    0.00000000
      16      0.00000000   -0.00819519
      17     -0.05229773    0.00000000
      18      0.00000000    0.03421551
      20      0.00000000    0.05744933
      21      0.36818092    0.00000000
      22      0.00000000    0.28661069

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000   -0.00125903
       2      0.00000000    0.00000000    0.00000000    0.00000000    0.01257758
       3      0.00000000    0.00000000    0.00000000    0.00000000   -0.00178030
       4      0.00000000    0.00000000    0.00000000    0.00000000    0.04670319
       5     -0.00125903    0.01257758   -0.00178030    0.04670319    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000    0.08645139
       8      0.00313457   -0.02226892   -0.00799790   -0.28816378    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000   -0.31446957
      11      0.00857490   -0.01325025    0.00340758    0.19103630    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000    0.00082324
      14      0.00000000    0.00000000    0.00000000    0.00000000    0.01018635
      15      0.00078113   -0.00048236    0.00536273   -0.01109798    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000   -0.01064085
      17      0.00123228   -0.00383311   -0.01205857    0.08953878    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000    0.15337933
      20      0.00000000    0.00000000    0.00000000    0.00000000    0.00972923
      21      0.00095014   -0.00025372   -0.00672482   -0.00311203    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000    0.02249044

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000    0.00313457    0.00000000    0.00000000
       2      0.00000000    0.00000000   -0.02226892    0.00000000    0.00000000
       3      0.00000000    0.00000000   -0.00799790    0.00000000    0.00000000
       4      0.00000000    0.00000000   -0.28816378    0.00000000    0.00000000
       5      0.08645139    0.00000000    0.00000000    0.00000000   -0.31446957
       6      0.00000000    0.00000000   -0.42058242    0.00000000    0.00000000
       8     -0.42058242    0.00000000    0.00000000    0.00000000   -1.08561501
      10      0.00000000    0.00000000   -1.08561501    0.00000000    0.00000000
      11     -0.38332752    0.00000000    0.00000000    0.00000000    0.83362156
      12      0.00000000    0.00000000   -0.23166528    0.00000000    0.00000000
      14      0.00000000    0.00000000   -0.21300169    0.00000000    0.00000000
      15     -0.02621708    0.00000000    0.00000000    0.00000000    0.25116321
      16      0.00000000    0.00000000    0.07158936    0.00000000    0.00000000
      17      0.07810123    0.00000000    0.00000000    0.00000000    0.19045516
      18      0.00000000    0.00000000   -0.21648511    0.00000000    0.00000000
      20      0.00000000    0.00000000    0.06048446    0.00000000    0.00000000
      21     -0.04999279    0.00000000    0.00000000    0.00000000    0.10634632
      22      0.00000000    0.00000000    0.10143387    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00857490    0.00000000    0.00000000    0.00000000    0.00078113
       2     -0.01325025    0.00000000    0.00000000    0.00000000   -0.00048236
       3      0.00340758    0.00000000    0.00000000    0.00000000    0.00536273
       4      0.19103630    0.00000000    0.00000000    0.00000000   -0.01109798
       5      0.00000000    0.00082324    0.00000000    0.01018635    0.00000000
       6     -0.38332752    0.00000000    0.00000000    0.00000000   -0.02621708
       8      0.00000000   -0.23166528    0.00000000   -0.21300169    0.00000000
      10      0.83362156    0.00000000    0.00000000    0.00000000    0.25116321
      11      0.00000000    0.18678368    0.00000000   -0.06088119    0.00000000
      12      0.18678368    0.00000000    0.00000000    0.00000000   -0.02232323
      14     -0.06088119    0.00000000    0.00000000    0.00000000   -0.02142338
      15      0.00000000   -0.02232323    0.00000000   -0.02142338    0.00000000
      16     -0.06332720    0.00000000    0.00000000    0.00000000   -0.02917461
      17      0.00000000    0.03609643    0.00000000   -0.00632741    0.00000000
      18     -0.03302325    0.00000000    0.00000000    0.00000000    0.00134731
      20      0.04113564    0.00000000    0.00000000    0.00000000    0.00701138
      21      0.00000000    0.02316070    0.00000000   -0.00451389    0.00000000
      22      0.00025526    0.00000000    0.00000000    0.00000000    0.00647474

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000    0.00123228    0.00000000    0.00000000    0.00000000
       2      0.00000000   -0.00383311    0.00000000    0.00000000    0.00000000
       3      0.00000000   -0.01205857    0.00000000    0.00000000    0.00000000
       4      0.00000000    0.08953878    0.00000000    0.00000000    0.00000000
       5     -0.01064085    0.00000000    0.15337933    0.00000000    0.00972923
       6      0.00000000    0.07810123    0.00000000    0.00000000    0.00000000
       8      0.07158936    0.00000000   -0.21648511    0.00000000    0.06048446
      10      0.00000000    0.19045516    0.00000000    0.00000000    0.00000000
      11     -0.06332720    0.00000000   -0.03302325    0.00000000    0.04113564
      12      0.00000000    0.03609643    0.00000000    0.00000000    0.00000000
      14      0.00000000   -0.00632741    0.00000000    0.00000000    0.00000000
      15     -0.02917461    0.00000000    0.00134731    0.00000000    0.00701138
      16      0.00000000   -0.01928226    0.00000000    0.00000000    0.00000000
      17     -0.01928226    0.00000000   -0.01143886    0.00000000    0.00347862
      18      0.00000000   -0.01143886    0.00000000    0.00000000    0.00000000
      20      0.00000000    0.00347862    0.00000000    0.00000000    0.00000000
      21     -0.00893367    0.00000000    0.00431557    0.00000000    0.00985426
      22      0.00000000   -0.00148392    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1      0.00095014    0.00000000
       2     -0.00025372    0.00000000
       3     -0.00672482    0.00000000
       4     -0.00311203    0.00000000
       5      0.00000000    0.02249044
       6     -0.04999279    0.00000000
       8      0.00000000    0.10143387
      10      0.10634632    0.00000000
      11      0.00000000    0.00025526
      12      0.02316070    0.00000000
      14     -0.00451389    0.00000000
      15      0.00000000    0.00647474
      16     -0.00893367    0.00000000
      17      0.00000000   -0.00148392
      18      0.00431557    0.00000000
      20      0.00985426    0.00000000
      21      0.00000000    0.00318117
      22      0.00318117    0.00000000
 Norm of TOPGET   2.36387736
 Vector in PCM1GR
 (Reference state)


 Density matrix in PCP1GR


 One electron matrix in PCM1GR

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000    0.00125903
       2      0.00000000    0.00000000    0.00000000    0.00000000   -0.01257758
       3      0.00000000    0.00000000    0.00000000    0.00000000    0.00178030
       4      0.00000000    0.00000000    0.00000000    0.00000000   -0.04670319
       5      0.00125903   -0.01257758    0.00178030   -0.04670319    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000   -0.08645139
       8     -0.00313457    0.02226892    0.00799790    0.28816378    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000    0.31446957
      11     -0.00857490    0.01325025   -0.00340758   -0.19103630    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000   -0.00082324
      14      0.00000000    0.00000000    0.00000000    0.00000000   -0.01018635
      15     -0.00078113    0.00048236   -0.00536273    0.01109798    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000    0.01064085
      17     -0.00123228    0.00383311    0.01205857   -0.08953878    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000   -0.15337933
      20      0.00000000    0.00000000    0.00000000    0.00000000   -0.00972923
      21     -0.00095014    0.00025372    0.00672482    0.00311203    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000   -0.02249044

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000   -0.00313457    0.00000000    0.00000000
       2      0.00000000    0.00000000    0.02226892    0.00000000    0.00000000
       3      0.00000000    0.00000000    0.00799790    0.00000000    0.00000000
       4      0.00000000    0.00000000    0.28816378    0.00000000    0.00000000
       5     -0.08645139    0.00000000    0.00000000    0.00000000    0.31446957
       6      0.00000000    0.00000000    0.42058242    0.00000000    0.00000000
       8      0.42058242    0.00000000    0.00000000    0.00000000    1.08561501
      10      0.00000000    0.00000000    1.08561501    0.00000000    0.00000000
      11      0.38332752    0.00000000    0.00000000    0.00000000   -0.83362156
      12      0.00000000    0.00000000    0.23166528    0.00000000    0.00000000
      14      0.00000000    0.00000000    0.21300169    0.00000000    0.00000000
      15      0.02621708    0.00000000    0.00000000    0.00000000   -0.25116321
      16      0.00000000    0.00000000   -0.07158936    0.00000000    0.00000000
      17     -0.07810123    0.00000000    0.00000000    0.00000000   -0.19045516
      18      0.00000000    0.00000000    0.21648511    0.00000000    0.00000000
      20      0.00000000    0.00000000   -0.06048446    0.00000000    0.00000000
      21      0.04999279    0.00000000    0.00000000    0.00000000   -0.10634632
      22      0.00000000    0.00000000   -0.10143387    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1     -0.00857490    0.00000000    0.00000000    0.00000000   -0.00078113
       2      0.01325025    0.00000000    0.00000000    0.00000000    0.00048236
       3     -0.00340758    0.00000000    0.00000000    0.00000000   -0.00536273
       4     -0.19103630    0.00000000    0.00000000    0.00000000    0.01109798
       5      0.00000000   -0.00082324    0.00000000   -0.01018635    0.00000000
       6      0.38332752    0.00000000    0.00000000    0.00000000    0.02621708
       8      0.00000000    0.23166528    0.00000000    0.21300169    0.00000000
      10     -0.83362156    0.00000000    0.00000000    0.00000000   -0.25116321
      11      0.00000000   -0.18678368    0.00000000    0.06088119    0.00000000
      12     -0.18678368    0.00000000    0.00000000    0.00000000    0.02232323
      14      0.06088119    0.00000000    0.00000000    0.00000000    0.02142338
      15      0.00000000    0.02232323    0.00000000    0.02142338    0.00000000
      16      0.06332720    0.00000000    0.00000000    0.00000000    0.02917461
      17      0.00000000   -0.03609643    0.00000000    0.00632741    0.00000000
      18      0.03302325    0.00000000    0.00000000    0.00000000   -0.00134731
      20     -0.04113564    0.00000000    0.00000000    0.00000000   -0.00701138
      21      0.00000000   -0.02316070    0.00000000    0.00451389    0.00000000
      22     -0.00025526    0.00000000    0.00000000    0.00000000   -0.00647474

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000   -0.00123228    0.00000000    0.00000000    0.00000000
       2      0.00000000    0.00383311    0.00000000    0.00000000    0.00000000
       3      0.00000000    0.01205857    0.00000000    0.00000000    0.00000000
       4      0.00000000   -0.08953878    0.00000000    0.00000000    0.00000000
       5      0.01064085    0.00000000   -0.15337933    0.00000000   -0.00972923
       6      0.00000000   -0.07810123    0.00000000    0.00000000    0.00000000
       8     -0.07158936    0.00000000    0.21648511    0.00000000   -0.06048446
      10      0.00000000   -0.19045516    0.00000000    0.00000000    0.00000000
      11      0.06332720    0.00000000    0.03302325    0.00000000   -0.04113564
      12      0.00000000   -0.03609643    0.00000000    0.00000000    0.00000000
      14      0.00000000    0.00632741    0.00000000    0.00000000    0.00000000
      15      0.02917461    0.00000000   -0.00134731    0.00000000   -0.00701138
      16      0.00000000    0.01928226    0.00000000    0.00000000    0.00000000
      17      0.01928226    0.00000000    0.01143886    0.00000000   -0.00347862
      18      0.00000000    0.01143886    0.00000000    0.00000000    0.00000000
      20      0.00000000   -0.00347862    0.00000000    0.00000000    0.00000000
      21      0.00893367    0.00000000   -0.00431557    0.00000000   -0.00985426
      22      0.00000000    0.00148392    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1     -0.00095014    0.00000000
       2      0.00025372    0.00000000
       3      0.00672482    0.00000000
       4      0.00311203    0.00000000
       5      0.00000000   -0.02249044
       6      0.04999279    0.00000000
       8      0.00000000   -0.10143387
      10     -0.10634632    0.00000000
      11      0.00000000   -0.00025526
      12     -0.02316070    0.00000000
      14      0.00451389    0.00000000
      15      0.00000000   -0.00647474
      16      0.00893367    0.00000000
      17      0.00000000    0.00148392
      18     -0.00431557    0.00000000
      20     -0.00985426    0.00000000
      21      0.00000000   -0.00318117
      22     -0.00318117    0.00000000

              Column   1
       1      0.00065660
       2      0.00071223
       3      0.00030737
       4      0.00009812
       5      0.00027284
       6      0.00013192
       7      0.00005079
       8      0.00170651
       9      0.00338047
      10      0.00280277
      11      0.00347502
      12      0.00395888
      13      0.00181217
      14      0.00138339
      15      0.00227899
      16      0.00135990
      17      0.00043203
      18      0.00276448
      19      0.00418632
      20      0.00302545
      21      0.00263597
      22      0.00279758
      23      0.00117428
      24      0.00065660
      25      0.00071223
      26      0.00030737
      27      0.00009812
      28      0.00027284
      29      0.00013192
      30      0.00005079
      31      0.00170651
      32      0.00338047
      33      0.00280277
      34      0.00347502
      35      0.00395888
      36      0.00181217
      37      0.00138339
      38      0.00227899
      39      0.00135990
      40      0.00043203
      41      0.00276448
      42      0.00418632
      43      0.00302545
      44      0.00263597
      45      0.00279758
      46      0.00117428
      47      0.00065660
      48      0.00071223
      49      0.00030737
      50      0.00009812
      51      0.00027284
      52      0.00013192
      53      0.00005079
      54      0.00170651
      55      0.00338047
      56      0.00280277
      57      0.00347502
      58      0.00395888
      59      0.00181217
      60      0.00138339
      61      0.00227899
      62      0.00135990
      63      0.00043203
      64      0.00276448
      65      0.00418632
      66      0.00302545
      67      0.00263597
      68      0.00279758
      69      0.00117428
      70      0.00065660
      71      0.00071223
      72      0.00030737
      73      0.00009812
      74      0.00027284
      75      0.00013192
      76      0.00005079
      77      0.00170651
      78      0.00338047
      79      0.00280277
      80      0.00347502
      81      0.00395888
      82      0.00181217
      83      0.00138339
      84      0.00227899
      85      0.00135990
      86      0.00043203
      87      0.00276448
      88      0.00418632
      89      0.00302545
      90      0.00263597
      91      0.00279758
      92      0.00117428
      93     -0.00118940
      94     -0.00182325
      95     -0.00097762
      96     -0.00162357
      97     -0.00048742
      98     -0.00137848
      99     -0.00093237
     100     -0.00124766
     101     -0.00212367
     102     -0.00135884
     103     -0.00144456
     104      0.00023081
     105      0.00020391
     106     -0.00035129
     107     -0.00025312
     108     -0.00117669
     109     -0.00127633
     110     -0.00085802
     111      0.00007236
     112     -0.00003469
     113     -0.00076707
     114     -0.00089992
     115     -0.00104507
     116     -0.00118940
     117     -0.00182325
     118     -0.00097762
     119     -0.00162357
     120     -0.00048742
     121     -0.00137848
     122     -0.00093237
     123     -0.00124766
     124     -0.00212367
     125     -0.00135884
     126     -0.00144456
     127      0.00023081
     128      0.00020391
     129     -0.00035129
     130     -0.00025312
     131     -0.00117669
     132     -0.00127633
     133     -0.00085802
     134      0.00007236
     135     -0.00003469
     136     -0.00076707
     137     -0.00089992
     138     -0.00104507
     139     -0.00118940
     140     -0.00182325
     141     -0.00097762
     142     -0.00162357
     143     -0.00048742
     144     -0.00137848
     145     -0.00093237
     146     -0.00124766
     147     -0.00212367
     148     -0.00135884
     149     -0.00144456
     150      0.00023081
     151      0.00020391
     152     -0.00035129
     153     -0.00025312
     154     -0.00117669
     155     -0.00127633
     156     -0.00085802
     157      0.00007236
     158     -0.00003469
     159     -0.00076707
     160     -0.00089992
     161     -0.00104507
     162     -0.00118940
     163     -0.00182325
     164     -0.00097762
     165     -0.00162357
     166     -0.00048742
     167     -0.00137848
     168     -0.00093237
     169     -0.00124766
     170     -0.00212367
     171     -0.00135884
     172     -0.00144456
     173      0.00023081
     174      0.00020391
     175     -0.00035129
     176     -0.00025312
     177     -0.00117669
     178     -0.00127633
     179     -0.00085802
     180      0.00007236
     181     -0.00003469
     182     -0.00076707
     183     -0.00089992
     184     -0.00104507
     185     -0.00109838
     186     -0.00195186
     187     -0.00180655
     188     -0.00105058
     189     -0.00166960
     190     -0.00050951
     191     -0.00184251
     192     -0.00179914
     193     -0.00167229
     194     -0.00074102
     195     -0.00092986
     196     -0.00161613
     197     -0.00016827
     198     -0.00153535
     199     -0.00041557
     200     -0.00120374
     201     -0.00110780
     202     -0.00067126
     203     -0.00109838
     204     -0.00195186
     205     -0.00180655
     206     -0.00105058
     207     -0.00166960
     208     -0.00050951
     209     -0.00184251
     210     -0.00179914
     211     -0.00167229
     212     -0.00074102
     213     -0.00092986
     214     -0.00161613
     215     -0.00016827
     216     -0.00153535
     217     -0.00041557
     218     -0.00120374
     219     -0.00110780
     220     -0.00067126
     221     -0.00120374
     222     -0.00110780
     223     -0.00067126
     224     -0.00109838
     225     -0.00195186
     226     -0.00180655
     227     -0.00105058
     228     -0.00166960
     229     -0.00050951
     230     -0.00184251
     231     -0.00179914
     232     -0.00167229
     233     -0.00074102
     234     -0.00092986
     235     -0.00161613
     236     -0.00016827
     237     -0.00153535
     238     -0.00041557
     239     -0.00120374
     240     -0.00110780
     241     -0.00067126
     242     -0.00109838
     243     -0.00195186
     244     -0.00180655
     245     -0.00105058
     246     -0.00166960
     247     -0.00050951
     248     -0.00184251
     249     -0.00179914
     250     -0.00167229
     251     -0.00074102
     252     -0.00092986
     253     -0.00161613
     254     -0.00016827
     255     -0.00153535
     256     -0.00041557

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.01658331    0.00000080   -0.00022321    0.00009966    0.00000000
       2      0.00000080   -0.00791792    0.00030212    0.00028251    0.00000000
       3     -0.00022321    0.00030212    0.00869793    0.00641381    0.00000000
       4      0.00009966    0.00028251    0.00641381   -0.01017231    0.00000000
       5      0.00000000    0.00000000    0.00000000    0.00000000   -0.00509122
       6     -0.00057669    0.00042608   -0.00506499   -0.01240929    0.00000000
       8      0.00000000    0.00000000    0.00000000    0.00000000    0.01340538
      10      0.00008079   -0.00024631   -0.00025563   -0.00154581    0.00000000
      11      0.00000000    0.00000000    0.00000000    0.00000000    0.00100009
      12      0.00016473    0.00014981   -0.00165720   -0.00338048    0.00000000
      14     -0.00040780   -0.00094430    0.00275846   -0.00216554    0.00000000
      15      0.00000000    0.00000000    0.00000000    0.00000000    0.00098860
      16      0.00013334    0.00054807   -0.00105002    0.00075940    0.00000000
      17      0.00000000    0.00000000    0.00000000    0.00000000    0.00087675
      18     -0.00037038    0.00020933    0.00088197    0.00140844    0.00000000
      20     -0.00077384    0.00005968    0.00139243    0.00187849    0.00000000
      21      0.00000000    0.00000000    0.00000000    0.00000000   -0.00110505
      22      0.00022584   -0.00009187   -0.00022323    0.00005285    0.00000000

              Column   6    Column   7    Column   8    Column   9    Column  10
       1     -0.00057669    0.00000000    0.00000000    0.00000000    0.00008079
       2      0.00042608    0.00000000    0.00000000    0.00000000   -0.00024631
       3     -0.00506499    0.00000000    0.00000000    0.00000000   -0.00025563
       4     -0.01240929    0.00000000    0.00000000    0.00000000   -0.00154581
       5      0.00000000    0.00000000    0.01340538    0.00000000    0.00000000
       6      0.01427023    0.00000000    0.00000000    0.00000000   -0.00322174
       7      0.00000000    0.00702526    0.00000000   -0.01265114    0.00000000
       8      0.00000000    0.00000000    0.00620403    0.00000000    0.00000000
       9      0.00000000   -0.01265114    0.00000000   -0.00006682    0.00000000
      10     -0.00322174    0.00000000    0.00000000    0.00000000   -0.01842104
      11      0.00000000    0.00000000   -0.00988713    0.00000000    0.00000000
      12     -0.00682668    0.00000000    0.00000000    0.00000000   -0.00050457
      13      0.00000000    0.00014698    0.00000000    0.00198052    0.00000000
      14      0.00496910    0.00000000    0.00000000    0.00000000   -0.00323590
      15      0.00000000    0.00000000   -0.00289255    0.00000000    0.00000000
      16     -0.00285122    0.00000000    0.00000000    0.00000000    0.00006689
      17      0.00000000    0.00000000   -0.00203465    0.00000000    0.00000000
      18      0.00119971    0.00000000    0.00000000    0.00000000   -0.00283759
      19      0.00000000    0.00166966    0.00000000    0.00197629    0.00000000
      20     -0.00377636    0.00000000    0.00000000    0.00000000    0.00056267
      21      0.00000000    0.00000000   -0.00218486    0.00000000    0.00000000
      22      0.00061555    0.00000000    0.00000000    0.00000000    0.00085912

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00000000    0.00016473    0.00000000   -0.00040780    0.00000000
       2      0.00000000    0.00014981    0.00000000   -0.00094430    0.00000000
       3      0.00000000   -0.00165720    0.00000000    0.00275846    0.00000000
       4      0.00000000   -0.00338048    0.00000000   -0.00216554    0.00000000
       5      0.00100009    0.00000000    0.00000000    0.00000000    0.00098860
       6      0.00000000   -0.00682668    0.00000000    0.00496910    0.00000000
       7      0.00000000    0.00000000    0.00014698    0.00000000    0.00000000
       8     -0.00988713    0.00000000    0.00000000    0.00000000   -0.00289255
       9      0.00000000    0.00000000    0.00198052    0.00000000    0.00000000
      10      0.00000000   -0.00050457    0.00000000   -0.00323590    0.00000000
      11     -0.01473714    0.00000000    0.00000000    0.00000000    0.00162327
      12      0.00000000   -0.00312371    0.00000000   -0.00588496    0.00000000
      13      0.00000000    0.00000000   -0.00997171    0.00000000    0.00000000
      14      0.00000000   -0.00588496    0.00000000   -0.00684478    0.00000000
      15      0.00162327    0.00000000    0.00000000    0.00000000   -0.00413352
      16      0.00000000   -0.00149438    0.00000000   -0.00810183    0.00000000
      17      0.00526408    0.00000000    0.00000000    0.00000000   -0.00102513
      18      0.00000000    0.00329552    0.00000000    0.00542128    0.00000000
      19      0.00000000    0.00000000   -0.00336028    0.00000000    0.00000000
      20      0.00000000    0.00358708    0.00000000   -0.00144784    0.00000000
      21     -0.00075716    0.00000000    0.00000000    0.00000000   -0.00640066
      22      0.00000000    0.00609583    0.00000000    0.00114235    0.00000000

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00013334    0.00000000   -0.00037038    0.00000000   -0.00077384
       2      0.00054807    0.00000000    0.00020933    0.00000000    0.00005968
       3     -0.00105002    0.00000000    0.00088197    0.00000000    0.00139243
       4      0.00075940    0.00000000    0.00140844    0.00000000    0.00187849
       5      0.00000000    0.00087675    0.00000000    0.00000000    0.00000000
       6     -0.00285122    0.00000000    0.00119971    0.00000000   -0.00377636
       7      0.00000000    0.00000000    0.00000000    0.00166966    0.00000000
       8      0.00000000   -0.00203465    0.00000000    0.00000000    0.00000000
       9      0.00000000    0.00000000    0.00000000    0.00197629    0.00000000
      10      0.00006689    0.00000000   -0.00283759    0.00000000    0.00056267
      11      0.00000000    0.00526408    0.00000000    0.00000000    0.00000000
      12     -0.00149438    0.00000000    0.00329552    0.00000000    0.00358708
      13      0.00000000    0.00000000    0.00000000   -0.00336028    0.00000000
      14     -0.00810183    0.00000000    0.00542128    0.00000000   -0.00144784
      15      0.00000000   -0.00102513    0.00000000    0.00000000    0.00000000
      16     -0.01477298    0.00000000   -0.00311813    0.00000000    0.00266310
      17      0.00000000   -0.01712229    0.00000000    0.00000000    0.00000000
      18     -0.00311813    0.00000000   -0.00907365    0.00000000    0.00991820
      19      0.00000000    0.00000000    0.00000000    0.01624686    0.00000000
      20      0.00266310    0.00000000    0.00991820    0.00000000    0.02170812
      21      0.00000000   -0.00273572    0.00000000    0.00000000    0.00000000
      22     -0.00069656    0.00000000    0.00212587    0.00000000    0.00343627

              Column  21    Column  22
       1      0.00000000    0.00022584
       2      0.00000000   -0.00009187
       3      0.00000000   -0.00022323
       4      0.00000000    0.00005285
       5     -0.00110505    0.00000000
       6      0.00000000    0.00061555
       8     -0.00218486    0.00000000
      10      0.00000000    0.00085912
      11     -0.00075716    0.00000000
      12      0.00000000    0.00609583
      14      0.00000000    0.00114235
      15     -0.00640066    0.00000000
      16      0.00000000   -0.00069656
      17     -0.00273572    0.00000000
      18      0.00000000    0.00212587
      20      0.00000000    0.00343627
      21      0.01634647    0.00000000
      22      0.00000000    0.01093001

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000    0.00018060
       2      0.00000000    0.00000000    0.00000000    0.00000000   -0.00027643
       3      0.00000000    0.00000000    0.00000000    0.00000000    0.00026770
       4      0.00000000    0.00000000    0.00000000    0.00000000    0.00973199
       5      0.00018060   -0.00027643    0.00026770    0.00973199    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000    0.00212146
       8     -0.00077097    0.00114634   -0.00290056    0.00651193    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000    0.02757241
      11      0.00002174   -0.00007632   -0.00029779   -0.02866400    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000    0.00571735
      14      0.00000000    0.00000000    0.00000000    0.00000000   -0.00167395
      15     -0.00001466    0.00002549   -0.00004004   -0.00304120    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000   -0.00219788
      17      0.00002305   -0.00004488    0.00001219   -0.00423238    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000   -0.00079297
      20      0.00000000    0.00000000    0.00000000    0.00000000    0.00152277
      21     -0.00001923    0.00001581    0.00000117   -0.00380933    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000    0.00042790

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000   -0.00077097    0.00000000    0.00000000
       2      0.00000000    0.00000000    0.00114634    0.00000000    0.00000000
       3      0.00000000    0.00000000   -0.00290056    0.00000000    0.00000000
       4      0.00000000    0.00000000    0.00651193    0.00000000    0.00000000
       5      0.00212146    0.00000000    0.00000000    0.00000000    0.02757241
       6      0.00000000    0.00000000    0.05885968    0.00000000    0.00000000
       8      0.05885968    0.00000000    0.00000000    0.00000000   -0.13379566
      10      0.00000000    0.00000000   -0.13379566    0.00000000    0.00000000
      11     -0.05243211    0.00000000    0.00000000    0.00000000   -0.06348942
      12      0.00000000    0.00000000   -0.02378847    0.00000000    0.00000000
      14      0.00000000    0.00000000    0.00599528    0.00000000    0.00000000
      15     -0.00559554    0.00000000    0.00000000    0.00000000    0.01217980
      16      0.00000000    0.00000000    0.01158655    0.00000000    0.00000000
      17     -0.00730046    0.00000000    0.00000000    0.00000000    0.03125653
      18      0.00000000    0.00000000    0.00195119    0.00000000    0.00000000
      20      0.00000000    0.00000000   -0.00751069    0.00000000    0.00000000
      21     -0.00741903    0.00000000    0.00000000    0.00000000   -0.00146404
      22      0.00000000    0.00000000   -0.00208094    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00002174    0.00000000    0.00000000    0.00000000   -0.00001466
       2     -0.00007632    0.00000000    0.00000000    0.00000000    0.00002549
       3     -0.00029779    0.00000000    0.00000000    0.00000000   -0.00004004
       4     -0.02866400    0.00000000    0.00000000    0.00000000   -0.00304120
       5      0.00000000    0.00571735    0.00000000   -0.00167395    0.00000000
       6     -0.05243211    0.00000000    0.00000000    0.00000000   -0.00559554
       8      0.00000000   -0.02378847    0.00000000    0.00599528    0.00000000
      10     -0.06348942    0.00000000    0.00000000    0.00000000    0.01217980
      11      0.00000000   -0.01649278    0.00000000   -0.00820462    0.00000000
      12     -0.01649278    0.00000000    0.00000000    0.00000000   -0.00262042
      14     -0.00820462    0.00000000    0.00000000    0.00000000    0.00003201
      15      0.00000000   -0.00262042    0.00000000    0.00003201    0.00000000
      16      0.00344251    0.00000000    0.00000000    0.00000000   -0.00170011
      17      0.00000000    0.00130589    0.00000000   -0.00197553    0.00000000
      18     -0.00235323    0.00000000    0.00000000    0.00000000   -0.00017888
      20      0.00588154    0.00000000    0.00000000    0.00000000    0.00027924
      21      0.00000000   -0.00156026    0.00000000    0.00000788    0.00000000
      22      0.00240369    0.00000000    0.00000000    0.00000000    0.00002679

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000    0.00002305    0.00000000    0.00000000    0.00000000
       2      0.00000000   -0.00004488    0.00000000    0.00000000    0.00000000
       3      0.00000000    0.00001219    0.00000000    0.00000000    0.00000000
       4      0.00000000   -0.00423238    0.00000000    0.00000000    0.00000000
       5     -0.00219788    0.00000000   -0.00079297    0.00000000    0.00152277
       6      0.00000000   -0.00730046    0.00000000    0.00000000    0.00000000
       8      0.01158655    0.00000000    0.00195119    0.00000000   -0.00751069
      10      0.00000000    0.03125653    0.00000000    0.00000000    0.00000000
      11      0.00344251    0.00000000   -0.00235323    0.00000000    0.00588154
      12      0.00000000    0.00130589    0.00000000    0.00000000    0.00000000
      14      0.00000000   -0.00197553    0.00000000    0.00000000    0.00000000
      15     -0.00170011    0.00000000   -0.00017888    0.00000000    0.00027924
      16      0.00000000   -0.00518557    0.00000000    0.00000000    0.00000000
      17     -0.00518557    0.00000000    0.00065643    0.00000000    0.00132972
      18      0.00000000    0.00065643    0.00000000    0.00000000    0.00000000
      20      0.00000000    0.00132972    0.00000000    0.00000000    0.00000000
      21     -0.00040327    0.00000000    0.00005244    0.00000000    0.00041183
      22      0.00000000    0.00210399    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1     -0.00001923    0.00000000
       2      0.00001581    0.00000000
       3      0.00000117    0.00000000
       4     -0.00380933    0.00000000
       5      0.00000000    0.00042790
       6     -0.00741903    0.00000000
       8      0.00000000   -0.00208094
      10     -0.00146404    0.00000000
      11      0.00000000    0.00240369
      12     -0.00156026    0.00000000
      14      0.00000788    0.00000000
      15      0.00000000    0.00002679
      16     -0.00040327    0.00000000
      17      0.00000000    0.00210399
      18      0.00005244    0.00000000
      20      0.00041183    0.00000000
      21      0.00000000    0.00053912
      22      0.00053912    0.00000000
 Norm of TOPGET   0.12743991
 Vector in PCM1GR
 (Reference state)


 Density matrix in PCP1GR


 One electron matrix in PCM1GR

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000   -0.00009030
       2      0.00000000    0.00000000    0.00000000    0.00000000    0.00013822
       3      0.00000000    0.00000000    0.00000000    0.00000000   -0.00013385
       4      0.00000000    0.00000000    0.00000000    0.00000000   -0.00486600
       5     -0.00009030    0.00013822   -0.00013385   -0.00486600    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000   -0.00106073
       8      0.00038549   -0.00057317    0.00145028   -0.00325597    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000   -0.01378620
      11     -0.00001087    0.00003816    0.00014889    0.01433200    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000   -0.00285868
      14      0.00000000    0.00000000    0.00000000    0.00000000    0.00083697
      15      0.00000733   -0.00001274    0.00002002    0.00152060    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000    0.00109894
      17     -0.00001152    0.00002244   -0.00000610    0.00211619    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000    0.00039649
      20      0.00000000    0.00000000    0.00000000    0.00000000   -0.00076139
      21      0.00000961   -0.00000791   -0.00000059    0.00190467    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000   -0.00021395

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000    0.00038549    0.00000000    0.00000000
       2      0.00000000    0.00000000   -0.00057317    0.00000000    0.00000000
       3      0.00000000    0.00000000    0.00145028    0.00000000    0.00000000
       4      0.00000000    0.00000000   -0.00325597    0.00000000    0.00000000
       5     -0.00106073    0.00000000    0.00000000    0.00000000   -0.01378620
       6      0.00000000    0.00000000   -0.02942984    0.00000000    0.00000000
       8     -0.02942984    0.00000000    0.00000000    0.00000000    0.06689783
      10      0.00000000    0.00000000    0.06689783    0.00000000    0.00000000
      11      0.02621605    0.00000000    0.00000000    0.00000000    0.03174471
      12      0.00000000    0.00000000    0.01189423    0.00000000    0.00000000
      14      0.00000000    0.00000000   -0.00299764    0.00000000    0.00000000
      15      0.00279777    0.00000000    0.00000000    0.00000000   -0.00608990
      16      0.00000000    0.00000000   -0.00579327    0.00000000    0.00000000
      17      0.00365023    0.00000000    0.00000000    0.00000000   -0.01562826
      18      0.00000000    0.00000000   -0.00097560    0.00000000    0.00000000
      20      0.00000000    0.00000000    0.00375535    0.00000000    0.00000000
      21      0.00370952    0.00000000    0.00000000    0.00000000    0.00073202
      22      0.00000000    0.00000000    0.00104047    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1     -0.00001087    0.00000000    0.00000000    0.00000000    0.00000733
       2      0.00003816    0.00000000    0.00000000    0.00000000   -0.00001274
       3      0.00014889    0.00000000    0.00000000    0.00000000    0.00002002
       4      0.01433200    0.00000000    0.00000000    0.00000000    0.00152060
       5      0.00000000   -0.00285868    0.00000000    0.00083697    0.00000000
       6      0.02621605    0.00000000    0.00000000    0.00000000    0.00279777
       8      0.00000000    0.01189423    0.00000000   -0.00299764    0.00000000
      10      0.03174471    0.00000000    0.00000000    0.00000000   -0.00608990
      11      0.00000000    0.00824639    0.00000000    0.00410231    0.00000000
      12      0.00824639    0.00000000    0.00000000    0.00000000    0.00131021
      14      0.00410231    0.00000000    0.00000000    0.00000000   -0.00001600
      15      0.00000000    0.00131021    0.00000000   -0.00001600    0.00000000
      16     -0.00172126    0.00000000    0.00000000    0.00000000    0.00085005
      17      0.00000000   -0.00065294    0.00000000    0.00098776    0.00000000
      18      0.00117661    0.00000000    0.00000000    0.00000000    0.00008944
      20     -0.00294077    0.00000000    0.00000000    0.00000000   -0.00013962
      21      0.00000000    0.00078013    0.00000000   -0.00000394    0.00000000
      22     -0.00120184    0.00000000    0.00000000    0.00000000   -0.00001340

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000   -0.00001152    0.00000000    0.00000000    0.00000000
       2      0.00000000    0.00002244    0.00000000    0.00000000    0.00000000
       3      0.00000000   -0.00000610    0.00000000    0.00000000    0.00000000
       4      0.00000000    0.00211619    0.00000000    0.00000000    0.00000000
       5      0.00109894    0.00000000    0.00039649    0.00000000   -0.00076139
       6      0.00000000    0.00365023    0.00000000    0.00000000    0.00000000
       8     -0.00579327    0.00000000   -0.00097560    0.00000000    0.00375535
      10      0.00000000   -0.01562826    0.00000000    0.00000000    0.00000000
      11     -0.00172126    0.00000000    0.00117661    0.00000000   -0.00294077
      12      0.00000000   -0.00065294    0.00000000    0.00000000    0.00000000
      14      0.00000000    0.00098776    0.00000000    0.00000000    0.00000000
      15      0.00085005    0.00000000    0.00008944    0.00000000   -0.00013962
      16      0.00000000    0.00259279    0.00000000    0.00000000    0.00000000
      17      0.00259279    0.00000000   -0.00032822    0.00000000   -0.00066486
      18      0.00000000   -0.00032822    0.00000000    0.00000000    0.00000000
      20      0.00000000   -0.00066486    0.00000000    0.00000000    0.00000000
      21      0.00020164    0.00000000   -0.00002622    0.00000000   -0.00020591
      22      0.00000000   -0.00105200    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1      0.00000961    0.00000000
       2     -0.00000791    0.00000000
       3     -0.00000059    0.00000000
       4      0.00190467    0.00000000
       5      0.00000000   -0.00021395
       6      0.00370952    0.00000000
       8      0.00000000    0.00104047
      10      0.00073202    0.00000000
      11      0.00000000   -0.00120184
      12      0.00078013    0.00000000
      14     -0.00000394    0.00000000
      15      0.00000000   -0.00001340
      16      0.00020164    0.00000000
      17      0.00000000   -0.00105200
      18     -0.00002622    0.00000000
      20     -0.00020591    0.00000000
      21      0.00000000   -0.00026956
      22     -0.00026956    0.00000000

              Column   1
       1      0.00065660
       2      0.00071223
       3      0.00030737
       4      0.00009812
       5      0.00027284
       6      0.00013192
       7      0.00005079
       8      0.00170651
       9      0.00338047
      10      0.00280277
      11      0.00347502
      12      0.00395888
      13      0.00181217
      14      0.00138339
      15      0.00227899
      16      0.00135990
      17      0.00043203
      18      0.00276448
      19      0.00418632
      20      0.00302545
      21      0.00263597
      22      0.00279758
      23      0.00117428
      24      0.00065660
      25      0.00071223
      26      0.00030737
      27      0.00009812
      28      0.00027284
      29      0.00013192
      30      0.00005079
      31      0.00170651
      32      0.00338047
      33      0.00280277
      34      0.00347502
      35      0.00395888
      36      0.00181217
      37      0.00138339
      38      0.00227899
      39      0.00135990
      40      0.00043203
      41      0.00276448
      42      0.00418632
      43      0.00302545
      44      0.00263597
      45      0.00279758
      46      0.00117428
      47      0.00065660
      48      0.00071223
      49      0.00030737
      50      0.00009812
      51      0.00027284
      52      0.00013192
      53      0.00005079
      54      0.00170651
      55      0.00338047
      56      0.00280277
      57      0.00347502
      58      0.00395888
      59      0.00181217
      60      0.00138339
      61      0.00227899
      62      0.00135990
      63      0.00043203
      64      0.00276448
      65      0.00418632
      66      0.00302545
      67      0.00263597
      68      0.00279758
      69      0.00117428
      70      0.00065660
      71      0.00071223
      72      0.00030737
      73      0.00009812
      74      0.00027284
      75      0.00013192
      76      0.00005079
      77      0.00170651
      78      0.00338047
      79      0.00280277
      80      0.00347502
      81      0.00395888
      82      0.00181217
      83      0.00138339
      84      0.00227899
      85      0.00135990
      86      0.00043203
      87      0.00276448
      88      0.00418632
      89      0.00302545
      90      0.00263597
      91      0.00279758
      92      0.00117428
      93     -0.00118940
      94     -0.00182325
      95     -0.00097762
      96     -0.00162357
      97     -0.00048742
      98     -0.00137848
      99     -0.00093237
     100     -0.00124766
     101     -0.00212367
     102     -0.00135884
     103     -0.00144456
     104      0.00023081
     105      0.00020391
     106     -0.00035129
     107     -0.00025312
     108     -0.00117669
     109     -0.00127633
     110     -0.00085802
     111      0.00007236
     112     -0.00003469
     113     -0.00076707
     114     -0.00089992
     115     -0.00104507
     116     -0.00118940
     117     -0.00182325
     118     -0.00097762
     119     -0.00162357
     120     -0.00048742
     121     -0.00137848
     122     -0.00093237
     123     -0.00124766
     124     -0.00212367
     125     -0.00135884
     126     -0.00144456
     127      0.00023081
     128      0.00020391
     129     -0.00035129
     130     -0.00025312
     131     -0.00117669
     132     -0.00127633
     133     -0.00085802
     134      0.00007236
     135     -0.00003469
     136     -0.00076707
     137     -0.00089992
     138     -0.00104507
     139     -0.00118940
     140     -0.00182325
     141     -0.00097762
     142     -0.00162357
     143     -0.00048742
     144     -0.00137848
     145     -0.00093237
     146     -0.00124766
     147     -0.00212367
     148     -0.00135884
     149     -0.00144456
     150      0.00023081
     151      0.00020391
     152     -0.00035129
     153     -0.00025312
     154     -0.00117669
     155     -0.00127633
     156     -0.00085802
     157      0.00007236
     158     -0.00003469
     159     -0.00076707
     160     -0.00089992
     161     -0.00104507
     162     -0.00118940
     163     -0.00182325
     164     -0.00097762
     165     -0.00162357
     166     -0.00048742
     167     -0.00137848
     168     -0.00093237
     169     -0.00124766
     170     -0.00212367
     171     -0.00135884
     172     -0.00144456
     173      0.00023081
     174      0.00020391
     175     -0.00035129
     176     -0.00025312
     177     -0.00117669
     178     -0.00127633
     179     -0.00085802
     180      0.00007236
     181     -0.00003469
     182     -0.00076707
     183     -0.00089992
     184     -0.00104507
     185     -0.00109838
     186     -0.00195186
     187     -0.00180655
     188     -0.00105058
     189     -0.00166960
     190     -0.00050951
     191     -0.00184251
     192     -0.00179914
     193     -0.00167229
     194     -0.00074102
     195     -0.00092986
     196     -0.00161613
     197     -0.00016827
     198     -0.00153535
     199     -0.00041557
     200     -0.00120374
     201     -0.00110780
     202     -0.00067126
     203     -0.00109838
     204     -0.00195186
     205     -0.00180655
     206     -0.00105058
     207     -0.00166960
     208     -0.00050951
     209     -0.00184251
     210     -0.00179914
     211     -0.00167229
     212     -0.00074102
     213     -0.00092986
     214     -0.00161613
     215     -0.00016827
     216     -0.00153535
     217     -0.00041557
     218     -0.00120374
     219     -0.00110780
     220     -0.00067126
     221     -0.00120374
     222     -0.00110780
     223     -0.00067126
     224     -0.00109838
     225     -0.00195186
     226     -0.00180655
     227     -0.00105058
     228     -0.00166960
     229     -0.00050951
     230     -0.00184251
     231     -0.00179914
     232     -0.00167229
     233     -0.00074102
     234     -0.00092986
     235     -0.00161613
     236     -0.00016827
     237     -0.00153535
     238     -0.00041557
     239     -0.00120374
     240     -0.00110780
     241     -0.00067126
     242     -0.00109838
     243     -0.00195186
     244     -0.00180655
     245     -0.00105058
     246     -0.00166960
     247     -0.00050951
     248     -0.00184251
     249     -0.00179914
     250     -0.00167229
     251     -0.00074102
     252     -0.00092986
     253     -0.00161613
     254     -0.00016827
     255     -0.00153535
     256     -0.00041557

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.01658331    0.00000080   -0.00022321    0.00009966    0.00000000
       2      0.00000080   -0.00791792    0.00030212    0.00028251    0.00000000
       3     -0.00022321    0.00030212    0.00869793    0.00641381    0.00000000
       4      0.00009966    0.00028251    0.00641381   -0.01017231    0.00000000
       5      0.00000000    0.00000000    0.00000000    0.00000000   -0.00509122
       6     -0.00057669    0.00042608   -0.00506499   -0.01240929    0.00000000
       8      0.00000000    0.00000000    0.00000000    0.00000000    0.01340538
      10      0.00008079   -0.00024631   -0.00025563   -0.00154581    0.00000000
      11      0.00000000    0.00000000    0.00000000    0.00000000    0.00100009
      12      0.00016473    0.00014981   -0.00165720   -0.00338048    0.00000000
      14     -0.00040780   -0.00094430    0.00275846   -0.00216554    0.00000000
      15      0.00000000    0.00000000    0.00000000    0.00000000    0.00098860
      16      0.00013334    0.00054807   -0.00105002    0.00075940    0.00000000
      17      0.00000000    0.00000000    0.00000000    0.00000000    0.00087675
      18     -0.00037038    0.00020933    0.00088197    0.00140844    0.00000000
      20     -0.00077384    0.00005968    0.00139243    0.00187849    0.00000000
      21      0.00000000    0.00000000    0.00000000    0.00000000   -0.00110505
      22      0.00022584   -0.00009187   -0.00022323    0.00005285    0.00000000

              Column   6    Column   7    Column   8    Column   9    Column  10
       1     -0.00057669    0.00000000    0.00000000    0.00000000    0.00008079
       2      0.00042608    0.00000000    0.00000000    0.00000000   -0.00024631
       3     -0.00506499    0.00000000    0.00000000    0.00000000   -0.00025563
       4     -0.01240929    0.00000000    0.00000000    0.00000000   -0.00154581
       5      0.00000000    0.00000000    0.01340538    0.00000000    0.00000000
       6      0.01427023    0.00000000    0.00000000    0.00000000   -0.00322174
       7      0.00000000    0.00702526    0.00000000   -0.01265114    0.00000000
       8      0.00000000    0.00000000    0.00620403    0.00000000    0.00000000
       9      0.00000000   -0.01265114    0.00000000   -0.00006682    0.00000000
      10     -0.00322174    0.00000000    0.00000000    0.00000000   -0.01842104
      11      0.00000000    0.00000000   -0.00988713    0.00000000    0.00000000
      12     -0.00682668    0.00000000    0.00000000    0.00000000   -0.00050457
      13      0.00000000    0.00014698    0.00000000    0.00198052    0.00000000
      14      0.00496910    0.00000000    0.00000000    0.00000000   -0.00323590
      15      0.00000000    0.00000000   -0.00289255    0.00000000    0.00000000
      16     -0.00285122    0.00000000    0.00000000    0.00000000    0.00006689
      17      0.00000000    0.00000000   -0.00203465    0.00000000    0.00000000
      18      0.00119971    0.00000000    0.00000000    0.00000000   -0.00283759
      19      0.00000000    0.00166966    0.00000000    0.00197629    0.00000000
      20     -0.00377636    0.00000000    0.00000000    0.00000000    0.00056267
      21      0.00000000    0.00000000   -0.00218486    0.00000000    0.00000000
      22      0.00061555    0.00000000    0.00000000    0.00000000    0.00085912

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00000000    0.00016473    0.00000000   -0.00040780    0.00000000
       2      0.00000000    0.00014981    0.00000000   -0.00094430    0.00000000
       3      0.00000000   -0.00165720    0.00000000    0.00275846    0.00000000
       4      0.00000000   -0.00338048    0.00000000   -0.00216554    0.00000000
       5      0.00100009    0.00000000    0.00000000    0.00000000    0.00098860
       6      0.00000000   -0.00682668    0.00000000    0.00496910    0.00000000
       7      0.00000000    0.00000000    0.00014698    0.00000000    0.00000000
       8     -0.00988713    0.00000000    0.00000000    0.00000000   -0.00289255
       9      0.00000000    0.00000000    0.00198052    0.00000000    0.00000000
      10      0.00000000   -0.00050457    0.00000000   -0.00323590    0.00000000
      11     -0.01473714    0.00000000    0.00000000    0.00000000    0.00162327
      12      0.00000000   -0.00312371    0.00000000   -0.00588496    0.00000000
      13      0.00000000    0.00000000   -0.00997171    0.00000000    0.00000000
      14      0.00000000   -0.00588496    0.00000000   -0.00684478    0.00000000
      15      0.00162327    0.00000000    0.00000000    0.00000000   -0.00413352
      16      0.00000000   -0.00149438    0.00000000   -0.00810183    0.00000000
      17      0.00526408    0.00000000    0.00000000    0.00000000   -0.00102513
      18      0.00000000    0.00329552    0.00000000    0.00542128    0.00000000
      19      0.00000000    0.00000000   -0.00336028    0.00000000    0.00000000
      20      0.00000000    0.00358708    0.00000000   -0.00144784    0.00000000
      21     -0.00075716    0.00000000    0.00000000    0.00000000   -0.00640066
      22      0.00000000    0.00609583    0.00000000    0.00114235    0.00000000

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00013334    0.00000000   -0.00037038    0.00000000   -0.00077384
       2      0.00054807    0.00000000    0.00020933    0.00000000    0.00005968
       3     -0.00105002    0.00000000    0.00088197    0.00000000    0.00139243
       4      0.00075940    0.00000000    0.00140844    0.00000000    0.00187849
       5      0.00000000    0.00087675    0.00000000    0.00000000    0.00000000
       6     -0.00285122    0.00000000    0.00119971    0.00000000   -0.00377636
       7      0.00000000    0.00000000    0.00000000    0.00166966    0.00000000
       8      0.00000000   -0.00203465    0.00000000    0.00000000    0.00000000
       9      0.00000000    0.00000000    0.00000000    0.00197629    0.00000000
      10      0.00006689    0.00000000   -0.00283759    0.00000000    0.00056267
      11      0.00000000    0.00526408    0.00000000    0.00000000    0.00000000
      12     -0.00149438    0.00000000    0.00329552    0.00000000    0.00358708
      13      0.00000000    0.00000000    0.00000000   -0.00336028    0.00000000
      14     -0.00810183    0.00000000    0.00542128    0.00000000   -0.00144784
      15      0.00000000   -0.00102513    0.00000000    0.00000000    0.00000000
      16     -0.01477298    0.00000000   -0.00311813    0.00000000    0.00266310
      17      0.00000000   -0.01712229    0.00000000    0.00000000    0.00000000
      18     -0.00311813    0.00000000   -0.00907365    0.00000000    0.00991820
      19      0.00000000    0.00000000    0.00000000    0.01624686    0.00000000
      20      0.00266310    0.00000000    0.00991820    0.00000000    0.02170812
      21      0.00000000   -0.00273572    0.00000000    0.00000000    0.00000000
      22     -0.00069656    0.00000000    0.00212587    0.00000000    0.00343627

              Column  21    Column  22
       1      0.00000000    0.00022584
       2      0.00000000   -0.00009187
       3      0.00000000   -0.00022323
       4      0.00000000    0.00005285
       5     -0.00110505    0.00000000
       6      0.00000000    0.00061555
       8     -0.00218486    0.00000000
      10      0.00000000    0.00085912
      11     -0.00075716    0.00000000
      12      0.00000000    0.00609583
      14      0.00000000    0.00114235
      15     -0.00640066    0.00000000
      16      0.00000000   -0.00069656
      17     -0.00273572    0.00000000
      18      0.00000000    0.00212587
      20      0.00000000    0.00343627
      21      0.01634647    0.00000000
      22      0.00000000    0.01093001

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000    0.00024830
       2      0.00000000    0.00000000    0.00000000    0.00000000   -0.00026658
       3      0.00000000    0.00000000    0.00000000    0.00000000    0.00015419
       4      0.00000000    0.00000000    0.00000000    0.00000000    0.01305327
       5      0.00024830   -0.00026658    0.00015419    0.01305327    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000   -0.00131632
       8     -0.00084564    0.00111846   -0.00439451    0.00869257    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000    0.02262911
      11      0.00040349   -0.00203713    0.00147422   -0.03649366    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000    0.00725329
      14      0.00000000    0.00000000    0.00000000    0.00000000   -0.00201641
      15      0.00002483   -0.00016908    0.00027524   -0.00444446    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000   -0.00094421
      17     -0.00000471    0.00001317    0.00055085   -0.00345801    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000   -0.00073093
      20      0.00000000    0.00000000    0.00000000    0.00000000    0.00223390
      21      0.00005405   -0.00023949    0.00018332   -0.00556615    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000    0.00021393

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000   -0.00084564    0.00000000    0.00000000
       2      0.00000000    0.00000000    0.00111846    0.00000000    0.00000000
       3      0.00000000    0.00000000   -0.00439451    0.00000000    0.00000000
       4      0.00000000    0.00000000    0.00869257    0.00000000    0.00000000
       5     -0.00131632    0.00000000    0.00000000    0.00000000    0.02262911
       6      0.00000000    0.00000000    0.06212246    0.00000000    0.00000000
       8      0.06212246    0.00000000    0.00000000    0.00000000   -0.07675785
      10      0.00000000    0.00000000   -0.07675785    0.00000000    0.00000000
      11     -0.05961825    0.00000000    0.00000000    0.00000000   -0.08182985
      12      0.00000000    0.00000000   -0.03433484    0.00000000    0.00000000
      14      0.00000000    0.00000000    0.00550615    0.00000000    0.00000000
      15     -0.00646150    0.00000000    0.00000000    0.00000000   -0.00017535
      16      0.00000000    0.00000000    0.00085650    0.00000000    0.00000000
      17     -0.00471768    0.00000000    0.00000000    0.00000000    0.00520995
      18      0.00000000    0.00000000    0.00217632    0.00000000    0.00000000
      20      0.00000000    0.00000000   -0.01005978    0.00000000    0.00000000
      21     -0.00916713    0.00000000    0.00000000    0.00000000   -0.01814303
      22      0.00000000    0.00000000   -0.00025177    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1      0.00040349    0.00000000    0.00000000    0.00000000    0.00002483
       2     -0.00203713    0.00000000    0.00000000    0.00000000   -0.00016908
       3      0.00147422    0.00000000    0.00000000    0.00000000    0.00027524
       4     -0.03649366    0.00000000    0.00000000    0.00000000   -0.00444446
       5      0.00000000    0.00725329    0.00000000   -0.00201641    0.00000000
       6     -0.05961825    0.00000000    0.00000000    0.00000000   -0.00646150
       8      0.00000000   -0.03433484    0.00000000    0.00550615    0.00000000
      10     -0.08182985    0.00000000    0.00000000    0.00000000   -0.00017535
      11      0.00000000   -0.02708517    0.00000000   -0.01200192    0.00000000
      12     -0.02708517    0.00000000    0.00000000    0.00000000   -0.00126075
      14     -0.01200192    0.00000000    0.00000000    0.00000000   -0.00044074
      15      0.00000000   -0.00126075    0.00000000   -0.00044074    0.00000000
      16      0.00588516    0.00000000    0.00000000    0.00000000    0.00012551
      17      0.00000000    0.00392062    0.00000000    0.00095091    0.00000000
      18     -0.02044055    0.00000000    0.00000000    0.00000000   -0.00154966
      20     -0.00344123    0.00000000    0.00000000    0.00000000   -0.00044576
      21      0.00000000   -0.00469801    0.00000000   -0.00249027    0.00000000
      22      0.00534509    0.00000000    0.00000000    0.00000000   -0.00007804

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000   -0.00000471    0.00000000    0.00000000    0.00000000
       2      0.00000000    0.00001317    0.00000000    0.00000000    0.00000000
       3      0.00000000    0.00055085    0.00000000    0.00000000    0.00000000
       4      0.00000000   -0.00345801    0.00000000    0.00000000    0.00000000
       5     -0.00094421    0.00000000   -0.00073093    0.00000000    0.00223390
       6      0.00000000   -0.00471768    0.00000000    0.00000000    0.00000000
       8      0.00085650    0.00000000    0.00217632    0.00000000   -0.01005978
      10      0.00000000    0.00520995    0.00000000    0.00000000    0.00000000
      11      0.00588516    0.00000000   -0.02044055    0.00000000   -0.00344123
      12      0.00000000    0.00392062    0.00000000    0.00000000    0.00000000
      14      0.00000000    0.00095091    0.00000000    0.00000000    0.00000000
      15      0.00012551    0.00000000   -0.00154966    0.00000000   -0.00044576
      16      0.00000000    0.00025283    0.00000000    0.00000000    0.00000000
      17      0.00025283    0.00000000    0.00011298    0.00000000    0.00036091
      18      0.00000000    0.00011298    0.00000000    0.00000000    0.00000000
      20      0.00000000    0.00036091    0.00000000    0.00000000    0.00000000
      21      0.00111609    0.00000000   -0.00214839    0.00000000    0.00025272
      22      0.00000000   -0.00034981    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1      0.00005405    0.00000000
       2     -0.00023949    0.00000000
       3      0.00018332    0.00000000
       4     -0.00556615    0.00000000
       5      0.00000000    0.00021393
       6     -0.00916713    0.00000000
       8      0.00000000   -0.00025177
      10     -0.01814303    0.00000000
      11      0.00000000    0.00534509
      12     -0.00469801    0.00000000
      14     -0.00249027    0.00000000
      15      0.00000000   -0.00007804
      16      0.00111609    0.00000000
      17      0.00000000   -0.00034981
      18     -0.00214839    0.00000000
      20      0.00025272    0.00000000
      21      0.00000000    0.00140200
      22      0.00140200    0.00000000
 Norm of TOPGET   0.112905346
 Vector in PCM1GR
 (Reference state)


 Density matrix in PCP1GR


 One electron matrix in PCM1GR

              Column   1    Column   2    Column   3    Column   4    Column   5
       1      0.00000000    0.00000000    0.00000000    0.00000000   -0.00012415
       2      0.00000000    0.00000000    0.00000000    0.00000000    0.00013329
       3      0.00000000    0.00000000    0.00000000    0.00000000   -0.00007710
       4      0.00000000    0.00000000    0.00000000    0.00000000   -0.00652664
       5     -0.00012415    0.00013329   -0.00007710   -0.00652664    0.00000000
       6      0.00000000    0.00000000    0.00000000    0.00000000    0.00065816
       8      0.00042282   -0.00055923    0.00219726   -0.00434629    0.00000000
      10      0.00000000    0.00000000    0.00000000    0.00000000   -0.01131455
      11     -0.00020175    0.00101856   -0.00073711    0.01824683    0.00000000
      12      0.00000000    0.00000000    0.00000000    0.00000000   -0.00362664
      14      0.00000000    0.00000000    0.00000000    0.00000000    0.00100820
      15     -0.00001242    0.00008454   -0.00013762    0.00222223    0.00000000
      16      0.00000000    0.00000000    0.00000000    0.00000000    0.00047210
      17      0.00000236   -0.00000659   -0.00027542    0.00172900    0.00000000
      18      0.00000000    0.00000000    0.00000000    0.00000000    0.00036546
      20      0.00000000    0.00000000    0.00000000    0.00000000   -0.00111695
      21     -0.00002703    0.00011974   -0.00009166    0.00278307    0.00000000
      22      0.00000000    0.00000000    0.00000000    0.00000000   -0.00010697

              Column   6    Column   7    Column   8    Column   9    Column  10
       1      0.00000000    0.00000000    0.00042282    0.00000000    0.00000000
       2      0.00000000    0.00000000   -0.00055923    0.00000000    0.00000000
       3      0.00000000    0.00000000    0.00219726    0.00000000    0.00000000
       4      0.00000000    0.00000000   -0.00434629    0.00000000    0.00000000
       5      0.00065816    0.00000000    0.00000000    0.00000000   -0.01131455
       6      0.00000000    0.00000000   -0.03106123    0.00000000    0.00000000
       8     -0.03106123    0.00000000    0.00000000    0.00000000    0.03837892
      10      0.00000000    0.00000000    0.03837892    0.00000000    0.00000000
      11      0.02980912    0.00000000    0.00000000    0.00000000    0.04091492
      12      0.00000000    0.00000000    0.01716742    0.00000000    0.00000000
      14      0.00000000    0.00000000   -0.00275307    0.00000000    0.00000000
      15      0.00323075    0.00000000    0.00000000    0.00000000    0.00008767
      16      0.00000000    0.00000000   -0.00042825    0.00000000    0.00000000
      17      0.00235884    0.00000000    0.00000000    0.00000000   -0.00260498
      18      0.00000000    0.00000000   -0.00108816    0.00000000    0.00000000
      20      0.00000000    0.00000000    0.00502989    0.00000000    0.00000000
      21      0.00458357    0.00000000    0.00000000    0.00000000    0.00907151
      22      0.00000000    0.00000000    0.00012588    0.00000000    0.00000000

              Column  11    Column  12    Column  13    Column  14    Column  15
       1     -0.00020175    0.00000000    0.00000000    0.00000000   -0.00001242
       2      0.00101856    0.00000000    0.00000000    0.00000000    0.00008454
       3     -0.00073711    0.00000000    0.00000000    0.00000000   -0.00013762
       4      0.01824683    0.00000000    0.00000000    0.00000000    0.00222223
       5      0.00000000   -0.00362664    0.00000000    0.00100820    0.00000000
       6      0.02980912    0.00000000    0.00000000    0.00000000    0.00323075
       8      0.00000000    0.01716742    0.00000000   -0.00275307    0.00000000
      10      0.04091492    0.00000000    0.00000000    0.00000000    0.00008767
      11      0.00000000    0.01354259    0.00000000    0.00600096    0.00000000
      12      0.01354259    0.00000000    0.00000000    0.00000000    0.00063037
      14      0.00600096    0.00000000    0.00000000    0.00000000    0.00022037
      15      0.00000000    0.00063037    0.00000000    0.00022037    0.00000000
      16     -0.00294258    0.00000000    0.00000000    0.00000000   -0.00006276
      17      0.00000000   -0.00196031    0.00000000   -0.00047545    0.00000000
      18      0.01022028    0.00000000    0.00000000    0.00000000    0.00077483
      20      0.00172062    0.00000000    0.00000000    0.00000000    0.00022288
      21      0.00000000    0.00234900    0.00000000    0.00124513    0.00000000
      22     -0.00267255    0.00000000    0.00000000    0.00000000    0.00003902

              Column  16    Column  17    Column  18    Column  19    Column  20
       1      0.00000000    0.00000236    0.00000000    0.00000000    0.00000000
       2      0.00000000   -0.00000659    0.00000000    0.00000000    0.00000000
       3      0.00000000   -0.00027542    0.00000000    0.00000000    0.00000000
       4      0.00000000    0.00172900    0.00000000    0.00000000    0.00000000
       5      0.00047210    0.00000000    0.00036546    0.00000000   -0.00111695
       6      0.00000000    0.00235884    0.00000000    0.00000000    0.00000000
       8     -0.00042825    0.00000000   -0.00108816    0.00000000    0.00502989
      10      0.00000000   -0.00260498    0.00000000    0.00000000    0.00000000
      11     -0.00294258    0.00000000    0.01022028    0.00000000    0.00172062
      12      0.00000000   -0.00196031    0.00000000    0.00000000    0.00000000
      14      0.00000000   -0.00047545    0.00000000    0.00000000    0.00000000
      15     -0.00006276    0.00000000    0.00077483    0.00000000    0.00022288
      16      0.00000000   -0.00012642    0.00000000    0.00000000    0.00000000
      17     -0.00012642    0.00000000   -0.00005649    0.00000000   -0.00018046
      18      0.00000000   -0.00005649    0.00000000    0.00000000    0.00000000
      20      0.00000000   -0.00018046    0.00000000    0.00000000    0.00000000
      21     -0.00055805    0.00000000    0.00107420    0.00000000   -0.00012636
      22      0.00000000    0.00017490    0.00000000    0.00000000    0.00000000

              Column  21    Column  22
       1     -0.00002703    0.00000000
       2      0.00011974    0.00000000
       3     -0.00009166    0.00000000
       4      0.00278307    0.00000000
       5      0.00000000   -0.00010697
       6      0.00458357    0.00000000
       8      0.00000000    0.00012588
      10      0.00907151    0.00000000
      11      0.00000000   -0.00267255
      12      0.00234900    0.00000000
      14      0.00124513    0.00000000
      15      0.00000000    0.00003902
      16     -0.00055805    0.00000000
      17      0.00000000    0.00017490
      18      0.00107420    0.00000000
      20     -0.00012636    0.00000000
      21      0.00000000   -0.00070100
      22     -0.00070100    0.00000000
@ B-freq = 0.000000  C-freq = 0.000000     beta(X;Z,X) =   -125.80876493

 >>>> Total CPU  time used in RESPONSE:  26.60 seconds
 >>>> Total wall time used in RESPONSE:  29.00 seconds
 >>>> Total CPU  time used in DALTON:  1 minute  11 seconds
 >>>> Total wall time used in DALTON:  1 minute  15 seconds

 
     Date and time (Linux)  : Tue Nov 13 11:11:19 2007
     Host name              : platina                                 
END REFOUT

