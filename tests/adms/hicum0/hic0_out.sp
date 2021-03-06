HICUM0 Output Test Ic=f(Vc,Ib)

IB 0 B 200n
VC C 0 2.0
VS S 0 0.0
X1 C B 0 S hicumL0V1p1_c_slh

.control
dc vc 0.0 3.0 0.05 ib 10u 100u 10u
run
plot abs(i(vc))
.endc

********************************************************************************
********************************************************************************
* HICUM Level0 Version 1.1 model cards for testing
********************************************************************************
********************************************************************************
* 1D transistor: Isothermal Simulation and Temperature dependence
********************************************************************************
.subckt hicumL0V1p1_1D c b e s
qhcm0 c b e s hic0_full
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=0.0 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_1D
********************************************************************************
* 1D transistor: Electrothermal Simulation to test self-heating
********************************************************************************
.subckt hicumL0V1p1_1D_slh c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=0.0 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=1000.0 cth=1.0e-10 
+ tnom=27.0 dt=0.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_1D_slh
********************************************************************************
* 1D transistor: Isothermal Simulation with NQS Effect: future
********************************************************************************
.subckt hicumL0V1p1_1D_nqs c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=0.0 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_1D_nqs
********************************************************************************
* 1D transistor: Isothermal Simulation to test collector current spreading
********************************************************************************
.subckt hicumL0V1p1_1D_ccs c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=0.0 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_1D_ccs
********************************************************************************
* Internal transistor: Isothermal Simulation and Temperature dependence (Tunneling current at peripheral node:future)
********************************************************************************
.subckt hicumL0V1p1_i_tnp c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_i_tnp
********************************************************************************
* Internal transistor: Isothermal Simulation and Temperature dependence (Tunneling current at internal node:future)
********************************************************************************
.subckt hicumL0V1p1_i_tni c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=0.0 fgeo=0.73 re=0.0 rcx=0.0 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=1.0e-20 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=0.0 cbcpar=0.0 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_i_tni
********************************************************************************
* Complete transistor: Isothermal Simulation and Temperature dependence
********************************************************************************
.subckt hicumL0V1p1_c c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c
********************************************************************************
* Complete transistor: Electrothermal Simulation to test self-heating
********************************************************************************
.subckt hicumL0V1p1_c_slh c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=1000.0 cth=1.0e-10 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c_slh
********************************************************************************
* Complete transistor: Isothermal Simulation with NQS Effect: future
********************************************************************************
.subckt hicumL0V1p1_c_nqs c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c_nqs
********************************************************************************
* Complete transistor: Isothermal Simulation to test collector current spreading
********************************************************************************
.subckt hicumL0V1p1_c_ccs c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=0.0 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=0.0 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0 
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c_ccs
********************************************************************************
* Complete transistor: Isothermal Simulation with substrate diode
********************************************************************************
.subckt hicumL0V1p1_c_sbt c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=1.0e-17 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=3.64e-14 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c_sbt
********************************************************************************
* Complete transistor: Isothermal Simulation with substrate network: future
********************************************************************************
.subckt hicumL0V1p1_c_sbn c b e s
qhcm0 c b e s hic0_full 
.model hic0_full npn level=7 is=1.3525E-18 vef=8.0 iqf=3.0e-2 iqr=1e6
+ iqfh=1e6 tfh=1e-8 ibes=1.16E-20 mbe=1.015 ires=1.16e-16 mre=2.0 ibcs=1.16e-20
+ mbc=1.015 mcf=1.0 mcr=1 kavl=0.9488 eavl=11.96e10 alkav=0.825e-4
+ aleav=0.196e-3 rbi0=71.76 rbx=8.83 fgeo=0.73 re=12.534 rcx=9.165 iscs=1.0e-17 msc=1.0
+ cje0=8.11e-15 vde=0.95 ze=0.5 aje=1.8 cjci0=1.16e-15 vdci=0.8 zci=0.333 
+ vptci=46 cjcx0=5.4e-15 vdcx=0.7 zcx=0.333 vptcx=100 fbc=0.1526 vr0e=1.6 vr0c=8.0
+ cjs0=3.64e-14 vds=0.6 zs=0.447 vpts=100 t0=4.75e-12 dt0h=2.1e-12 tbvl=4.0e-12
+ tef0=1.8e-12 gte=1.4 thcs=30.0e-12 ahc=0.75 tr=0.0 rci0=127.8 vlim=0.7 
+ vces=0.1 vpt=5 cbepar=1.13e-15 cbcpar=2.97e-15 kf=1.43e-8 af=2.0 vgb=1.17
+ alt0=0.0 kt0=0.0 zetaci=1.6 alvs=1.0e-3 alces=0.4e-3 zetarbi=0.588 
+ zetarbx=0.206 zetarcx=0.223 zetare=0.0 vge=1.1386 vgc=1.1143 vgs=1.15 f1vg=-1.02377e-4
+ f2vg=4.3215e-4 zetact=3.5 zetabet=4.0 rth=0.0 cth=0.0
+ tnom=27.0 npn=1 pnp=0
*+ dt=0.0
.ends hicumL0V1p1_c_sbn
********************************************************************************
* Complete test transistor: default
********************************************************************************
.subckt hicumL0V11_default c b e s
qhcm0 c b e s hic0_full
.ends hicumL0V11_default
********************************************************************************

.end
