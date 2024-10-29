c**********************   february 14, 2001  *****************************
cccshie 8/19/04
c     subroutine irrad (m,np,pl,ta,wa,oa,tb,ts,co2,
      subroutine irrad (m,np,jj2,pl,ta,wa,oa,tb,ts,co2,
     *                  n2o,ch4,cfc11,cfc12,cfc22,emiss,
     *                  overcast,cldwater,cwc,taucl,reff,fcld,ict,icb,
c     *                  taual,ssaal,asyal,
     *                  high,trace,flx,flc,dfdts,sfcem)
      include 'radiation.h'
c***********************************************************************
c
c                        version ir-12 (february, 2001)
c
c  this version is evolved from version ir-8 with the following changes:
c   (1) apply a special treatment to the computations of radiation from 
c       ajacent layers.
c   (2) an option is available for the case that cloud fractional cover 
c       is either 0 or 1 (overcast=.true.). computation is faster with 
c       this option.
c   (3) an error in the data input "awb" was found and corrected.
c
c***********************************************************************
c
c                        version ir-11 (december, 2000)
c
c  new features of this version are:
c
c   (1) an option is available for the case that cloud fractional cover 
c       is either 0 or 1 (overcast=.true.). computation is faster with 
c       this option.
c
cc***********************************************************************
c
c                        version ir-10 (december, 2000)
c
c  new features of this version are:
c
c   (1) transmission between a level and the top of the atmosphere is 
c       corrected. in a previous version, this transmission was 
c       approximated by that between the level and the middle of the top
c       layer. a similar correction is applied to the the transmission 
c       between a level and the surface (see the parameters trntop and 
c       trnsfc). the largest effect of this adjustment is on the cooling 
c       rate of the top layer.
c
c***********************************************************************
c
c                        version ir-9 (november, 1999)
c
c  new features of this version are:
c
c   (1) the form of vertical integration for fluxes is changed from 
c       b*del(tau) to tau*del(b), where b is the planck function and tau 
c       is the transmission function.  flux calculaitons are more accurate 
c       with this new version especially when atmospheric layers are thick.
c   (2) errors in the data input "awb" were found and corrected.
c
c***********************************************************************
c
c                        version ir-8 (august, 1999)
c
c  cloud overlapping is treated according to eqs. (10)-(12) of chou and 
c   suarez (1994).
c  as previous versions, the form of vertical integration for fluxes is 
c   b*del(tau), where b is the planck function and tau is the transmission 
c   function.
c
c***********************************************************************
c
c                        version ir-7 (june, 1999)
c
c  the water vapor continuum absortion is included in the specral 
c   region 1215-1380 /cm.  clough's absorption data are used.
c
c***********************************************************************
c
c                        version ir-6 (april, 1999)
c
c  the co2 transmission functions are parameterized so that this code
c   can be applied to the case with a large range of co2 concentration
c   (up to 100 times of present value).  
c
c***********************************************************************
c
c                        version ir-5 (september, 1998)
c
c  new features of this version are:
c   (1) the effect of aerosol scattering on lw fluxes is included.
c   (2) absorption and scattering of rain drops are included.
c
c***********************************************************************
cc
c                        version ir-4 (october, 1997)
c
c  new features of this version are:
c   (1) the surface is treated as non-black.  the surface
c         emissivity, emiss, is an input parameter
c   (2) the effect of cloud scattering on lw fluxes is included
c
c*********************************************************************
c
c this routine computes ir fluxes due to water vapor, co2, o3,
c   trace gases (n2o, ch4, cfc11, cfc12, cfc22, co2-minor),
c   clouds, and aerosols.
c  
c this is a vectorized code.  it computes fluxes simultaneously for
c   m soundings.
c
c some detailed descriptions of the radiation routine are given in
c   chou and suarez (1994).
c
c ice and liquid cloud particles are allowed to co-exist in any of the
c  np layers. 
c
c if no information is available for the effective cloud particle size,
c  reff, default values of 10 micron for liquid water and 75 micron
c  for ice can be used.
c
c the maximum-random assumption is applied for cloud overlapping.
c  clouds are grouped into high, middle, and low clouds separated by the
c  level indices ict and icb.  within each of the three groups, clouds
c  are assumed maximally overlapped, and the cloud cover of a group is
c  the maximum cloud cover of all the layers in the group.  clouds among
c  the three groups are assumed randomly overlapped. the indices ict and
c  icb correpond approximately to the 400 mb and 700 mb levels.
c
c aerosols are allowed to be in any of the np layers. aerosol optical
c  properties can be specified as functions of height and spectral band.
c
c there are options for computing fluxes:
c
c   if overcast=.true., the layer cloud cover is either 0 or 1.
c   if overcast=.false., the cloud cover can be anywhere between 0 and 1.
c   computation is faster for the .true. option than the .false. option.
c
c   if cldwater=.true., taucl is computed from cwc and reff as a
c   function of height and spectral band. 
c   if cldwater=.false., taucl must be given as input to the radiation
c   routine. it is independent of spectral band.
c
c   if high = .true., transmission functions in the co2, o3, and the
c   three water vapor bands with strong absorption are computed using
c   table look-up.  cooling rates are computed accurately from the
c   surface up to 0.01 mb.
c   if high = .false., transmission functions are computed using the
c   k-distribution method with linear pressure scaling for all spectral
c   bands and gases.  cooling rates are not accurately calculated for
c   pressures less than 10 mb. the computation is faster with
c   high=.false. than with high=.true.
c   if trace = .true., absorption due to n2o, ch4, cfcs, and the 
c   two minor co2 bands in the window region is included.
c   if trace = .false., absorption in those minor bands is neglected.
c
c the ir spectrum is divided into nine bands:
c   
c   band     wavenumber (/cm)   absorber
c
c    1           0 - 340           h2o
c    2         340 - 540           h2o
c    3         540 - 800       h2o,cont,co2
c    4         800 - 980       h2o,cont
c                              co2,f11,f12,f22
c    5         980 - 1100      h2o,cont,o3
c                              co2,f11
c    6        1100 - 1215      h2o,cont
c                              n2o,ch4,f12,f22
c    7        1215 - 1380      h2o,cont
c                              n2o,ch4
c    8        1380 - 1900          h2o
c    9        1900 - 3000          h2o
c
c in addition, a narrow band in the 17 micrometer region is added to
c    compute flux reduction due to n2o
c
c    10        540 - 620       h2o,cont,co2,n2o
c
c band 3 (540-800/cm) is further divided into 3 sub-bands :
c
c   subband   wavenumber (/cm)
c
c    1          540 - 620
c    2          620 - 720
c    3          720 - 800
c
c---- input parameters                               units    size
c
c   number of soundings (m)                            --      1
c   number of atmospheric layers (np)                  --      1
c   level pressure (pl)                               mb      m*(np+1)
c   layer temperature (ta)                            k       m*np
c   layer specific humidity (wa)                      g/g     m*np
c   layer ozone mixing ratio by mass (oa)             g/g     m*np
c   surface air temperature (tb)                      k        m
c   surface temperature (ts)                          k        m
c   co2 mixing ratio by volumn (co2)                  pppv     1
c   n2o mixing ratio by volumn (n2o)                  pppv     1
c   ch4 mixing ratio by volumn (ch4)                  pppv     1
c   cfc11 mixing ratio by volumn (cfc11)              pppv     1
c   cfc12 mixing ratio by volumn (cfc12)              pppv     1
c   cfc22 mixing ratio by volumn (cfc22)              pppv     1
c   surface emissivity (emiss)                      fraction   m*10
c   input option for cloud fractional cover            --      1
c      (overcast)   (see explanation above)
c   input option for cloud optical thickness           --      1
c      (cldwater)   (see explanation above)
c   cloud water mixing ratio (cwc)                   gm/gm   m*np*3
c       index 1 for ice particles
c       index 2 for liquid drops
c       index 3 for rain drops
c   cloud optical thickness (taucl)                    --    m*np*3
c       index 1 for ice particles
c       index 2 for liquid drops
c       index 3 for rain drops
c   effective cloud-particle size (reff)          micrometer m*np*3
c       index 1 for ice particles
c       index 2 for liquid drops
c       index 3 for rain drops
c   cloud amount (fcld)                             fraction  m*np
c   level index separating high and middle             --      1
c       clouds (ict)
c   level index separating middle and low              --      1
c       clouds (icb)
c   aerosol optical thickness (taual)                  --   m*np*10
c   aerosol single-scattering albedo (ssaal)           --   m*np*10
c   aerosol asymmetry factor (asyal)                   --   m*np*10
c   high (see explanation above)                       --      1
c   trace (see explanation above)                      --      1
c
c data used in table look-up for transmittance calculations:
c
c   c1 , c2, c3: for co2 (band 3)
c   o1 , o2, o3: for  o3 (band 5)
c   h11,h12,h13: for h2o (band 1)
c   h21,h22,h23: for h2o (band 2)
c   h81,h82,h83: for h2o (band 8)
c
c---- output parameters
c
c   net downward flux, all-sky   (flx)             w/m**2  m*(np+1)
c   net downward flux, clear-sky (flc)             w/m**2  m*(np+1)
c   sensitivity of net downward flux  
c       to surface temperature (dfdts)            w/m**2/k m*(np+1)
c   emission by the surface (sfcem)                 w/m**2     m
c 
c notes: 
c
c   (1) water vapor continuum absorption is included in 540-1380 /cm.
c   (2) scattering is parameterized for clouds and aerosols.
c   (3) diffuse cloud and aerosol transmissions are computed
c       from exp(-1.66*tau).
c   (4) if there are no clouds, flx=flc.
c   (5) plevel(1) is the pressure at the top of the model atmosphere,
c        and plevel(np+1) is the surface pressure.
c   (6) downward flux is positive and upward flux is negative.
c   (7) sfcem and dfdts are negative because upward flux is defined as negative.
c   (8) for questions and coding errors, plaese contact ming-dah chou,
c       code 913, nasa/goddard space flight center, greenbelt, md 20771.
c       phone: 301-614-6192, fax: 301-614-6307,
c       e-mail: chou@climate.gsfc.nasa.gov
c
c***************************************************************************
cccshie 8/19/04
c     implicit none
!       parameter (nxf=4000,nyf=75,nzf=37,nt=38640,itt=244) 
!       parameter (lb=2,kb=1)
! ! define decomposition from rmp_switch.h
!       parameter (npes=1,ncol=1,nrow=1)
! ! define partial dimension for computation by decomposition
!       parameter (nx=(nxf-lb*2-1)/ncol+1+lb*2)
!       parameter (ny=1)
!       parameter (nz=nzf)
! ! define partial dimension for fft by transpose decomposition
!       parameter (nyc=1)
!       parameter (nyr= ny)
!       parameter (nxc= nx)
!       parameter (nxr=(nxf-lb*2-1)/nrow+1+lb*2)
!       parameter (nzc=(nzf-kb*2-1)/ncol+1+kb*2)
!       parameter (nzr=(nzf-kb*2-1)/nrow+1+kb*2)
!
!        parameter (nadd=7,lay=88)
c     integer nx1, ny1
      integer nx1, ny1, np1  ! cccshie 9/16/04
!       parameter(nx1=1,ny1=1,np1=100)   ! cccshie 9/16/04, create a "np1" domain .ge. (np+1) for acflxu(nx1,np1)
      parameter(nx1=1,ny1=1)   ! cccshie 9/16/04, create a "np1" domain .ge. (np+1) for acflxu(nx1,np1)
c---- input parameters ------
c     integer m,np,ict,icb
      integer m,np,jj2,ict,icb
      real pl(m,np+1),ta(m,np),wa(m,np),oa(m,np),
     *     tb(m),ts(m)
      real co2,n2o,ch4,cfc11,cfc12,cfc22,emiss(m,10)
      real cwc(m,np,3),taucl(m,np,3),reff(m,np,3),
     *     fcld(m,np)
      real taual(m,np,10),ssaal(m,np,10),asyal(m,np,10)
      logical overcast,cldwater,high,trace
c---- output parameters ------
      real flx(m,np+1),flc(m,np+1),dfdts(m,np+1),
     *     sfcem(m)
ccshie 8/19/04
c     real acflxu(nx1,np+1), acflxd(nx1,np+1)
!     real acflxu(nx1,np1), acflxd(nx1,np1)
      real ,  allocatable :: acflxu(:,:),acflxd(:,:)
      real rflux(nx1,ny1,8)
      common/radflux/rflux
c---- static data -----
      real cb(6,10),xkw(9),xke(9),aw(9),bw(9),pm(9),fkw(6,9),gkw(6,3)
      real aib(3,10),awb(4,10),aiw(4,10),aww(4,10),aig(4,10),awg(4,10)
      integer ne(9),mw(9)
c-----parameters defining the size of the pre-computed tables for
c     transmittance using table look-up.
cc    "nx" is the number of intervals in pressure
c     "nx2" is the number of intervals in pressure
c     "no" is the number of intervals in o3 amount
c     "nc" is the number of intervals in co2 amount
c     "nh" is the number of intervals in h2o amount
      integer nx2,no,nc,nh
c     parameter (nx=26,no=21,nc=30,nh=31)
      parameter (nx2=26,no=21,nc=30,nh=31) ! cccshie 9/15/04
      real c1 (nx2,nc),c2 (nx2,nc),c3 (nx2,nc)
      real o1 (nx2,no),o2 (nx2,no),o3 (nx2,no)
      real h11(nx2,nh),h12(nx2,nh),h13(nx2,nh)
      real h21(nx2,nh),h22(nx2,nh),h23(nx2,nh)
      real h71(nx2,nh),h72(nx2,nh),h73(nx2,nh)
      real h81(nx2,nh),h82(nx2,nh),h83(nx2,nh)
c---- temporary arrays -----
!     real pa(m,np),dt(m,np)
!     real sh2o(m,np+1),swpre(m,np+1),swtem(m,np+1)
!     real sco3(m,np+1),scopre(m,np+1),scotem(m,np+1)
!     real dh2o(m,np),dcont(m,np),dco2(m,np),do3(m,np)
!     real dn2o(m,np),dch4(m,np)
!     real df11(m,np),df12(m,np),df22(m,np)
!     real th2o(m,6),tcon(m,3),tco2(m,6,2)
!     real tn2o(m,4),tch4(m,4),tcom(m,6)
!     real tf11(m),tf12(m),tf22(m)
!     real h2oexp(m,np,6),conexp(m,np,3),co2exp(m,np,6,2)
!     real n2oexp(m,np,4),ch4exp(m,np,4),comexp(m,np,6)
!     real f11exp(m,np),f12exp(m,np),f22exp(m,np)
!     real blayer(m,0:np+1),blevel(m,np+1),dblayr(m,np+1),dbs(m)
!     real dp(m,np),cwp(m,np,3)
!     real trant(m),tranal(m),transfc(m,np+1),trantcr(m,np+1)
!     real flxu(m,np+1),flxd(m,np+1),flcu(m,np+1),flcd(m,np+1)
!     real rflx(m,np+1),rflc(m,np+1)
!     integer it(m),im(m),ib(m)
!     real cldhi(m),cldmd(m),cldlw(m),tcldlyr(m,np),fclr(m)
!     real taerlyr(m,np)
      real ,  allocatable :: pa(:,:),dt(:,:)
      real ,  allocatable :: sh2o(:,:),swpre(:,:),swtem(:,:)
      real ,  allocatable :: sco3(:,:),scopre(:,:),scotem(:,:)
      real ,  allocatable :: dh2o(:,:),dcont(:,:),dco2(:,:),do3(:,:)
      real ,  allocatable :: dn2o(:,:),dch4(:,:)
      real ,  allocatable :: df11(:,:),df12(:,:),df22(:,:)
      real ,  allocatable :: th2o(:,:),tcon(:,:),tco2(:,:,:)
      real ,  allocatable :: tn2o(:,:),tch4(:,:),tcom(:,:)
      real ,  allocatable :: tf11(:),tf12(:),tf22(:)
      real ,  allocatable :: h2oexp(:,:,:),conexp(:,:,:),co2exp(:,:,:,:)
      real ,  allocatable :: n2oexp(:,:,:),ch4exp(:,:,:),comexp(:,:,:)
      real ,  allocatable :: f11exp(:,:),f12exp(:,:),f22exp(:,:)
      real ,  allocatable :: blayer(:,:),blevel(:,:),dblayr(:,:),dbs(:)
      real ,  allocatable :: dp(:,:),cwp(:,:,:)
      real,allocatable :: trant(:),tranal(:),transfc(:,:),trantcr(:,:)
      real ,  allocatable :: flxu(:,:),flxd(:,:),flcu(:,:),flcd(:,:)
      real ,  allocatable :: rflx(:,:),rflc(:,:)
      integer,  allocatable :: it(:),im(:),ib(:)
      real,allocatable::cldhi(:),cldmd(:),cldlw(:),tcldlyr(:,:),fclr(:)
      real ,  allocatable :: taerlyr(:,:)
      integer i,j,k,ip,iw,ibn,ik,iq,isb,k1,k2
      real xx,yy,p1,dwe,dpe,a1,b1,fk1,a2,b2,fk2,bu,bd
      real w1,w2,w3,g1,g2,g3,ww,gg,ff,taux,reff1,reff2
      real tauxa
      logical oznbnd,co2bnd,h2otbl,conbnd,n2obnd
      logical ch4bnd,combnd,f11bnd,f12bnd,f22bnd,b10bnd
c-----the following coefficients are given in table 2 for computing  
c     spectrally integrated planck fluxes using eq. (3.11)
       data cb/
     1      5.3443e+0,  -2.0617e-1,   2.5333e-3,
     1     -6.8633e-6,   1.0115e-8,  -6.2672e-12,
     2      2.7148e+1,  -5.4038e-1,   2.9501e-3,
     2      2.7228e-7,  -9.3384e-9,   9.9677e-12,
     3     -3.4860e+1,   1.1132e+0,  -1.3006e-2,
     3      6.4955e-5,  -1.1815e-7,   8.0424e-11,
     4     -6.0513e+1,   1.4087e+0,  -1.2077e-2,
     4      4.4050e-5,  -5.6735e-8,   2.5660e-11,
     5     -2.6689e+1,   5.2828e-1,  -3.4453e-3,
     5      6.0715e-6,   1.2523e-8,  -2.1550e-11,
     6     -6.7274e+0,   4.2256e-2,   1.0441e-3,
     6     -1.2917e-5,   4.7396e-8,  -4.4855e-11,
     7      1.8786e+1,  -5.8359e-1,   6.9674e-3,
     7     -3.9391e-5,   1.0120e-7,  -8.2301e-11,
     8      1.0344e+2,  -2.5134e+0,   2.3748e-2,
     8     -1.0692e-4,   2.1841e-7,  -1.3704e-10,
     9     -1.0482e+1,   3.8213e-1,  -5.2267e-3,
     9      3.4412e-5,  -1.1075e-7,   1.4092e-10,
     *      1.6769e+0,   6.5397e-2,  -1.8125e-3,
     *      1.2912e-5,  -2.6715e-8,   1.9792e-11/
c-----xkw is the absorption coefficient are given in table 4 for the 
c     first k-distribution interval due to water vapor line absorption.
c     units are cm**2/g    
      data xkw / 29.55  , 4.167e-1, 1.328e-2, 5.250e-4,
     *           5.25e-4, 9.369e-3, 4.719e-2, 1.320e-0, 5.250e-4/
c-----xke is the absorption coefficient given in table 9 for the first
c     k-distribution function due to water vapor continuum absorption
c     units are cm**2/g
      data xke /  0.00,   0.00,   27.40,   15.8,
     *            9.40,   7.75,    8.78,    0.0,   0.0/
c-----mw is the ratio between neighboring absorption coefficients
c     for water vapor line absorption (table 4).
      data mw /6,6,8,6,6,8,9,6,16/
c-----aw and bw (table 3) are the coefficients for temperature scaling
c     in eq. (4.2).
      data aw/ 0.0021, 0.0140, 0.0167, 0.0302,
     *         0.0307, 0.0195, 0.0152, 0.0008, 0.0096/
      data bw/ -1.01e-5, 5.57e-5, 8.54e-5, 2.96e-4,
     *          2.86e-4, 1.108e-4, 7.608e-5, -3.52e-6, 1.64e-5/
c-----pm is the pressure-scaling parameter for water vapor absorption
c     eq. (4.1) and table 3.
      data pm/ 1.0, 1.0, 1.0, 1.0, 1.0, 0.77, 0.5, 1.0, 1.0/
c-----fkw is the planck-weighted k-distribution function due to h2o
c     line absorption given in table 4.
c     the k-distribution function for the third band, fkw(*,3), 
c     is not used (see the parameter gkw below).
      data fkw / 0.2747,0.2717,0.2752,0.1177,0.0352,0.0255,
     2           0.1521,0.3974,0.1778,0.1826,0.0374,0.0527,
     3           6*1.00,
     4           0.4654,0.2991,0.1343,0.0646,0.0226,0.0140,
     5           0.5543,0.2723,0.1131,0.0443,0.0160,0.0000,
     6           0.5955,0.2693,0.0953,0.0335,0.0064,0.0000,
     7           0.1958,0.3469,0.3147,0.1013,0.0365,0.0048,
     8           0.0740,0.1636,0.4174,0.1783,0.1101,0.0566,
     9           0.1437,0.2197,0.3185,0.2351,0.0647,0.0183/
c-----gkw is the planck-weighted k-distribution function due to h2o
c     line absorption in the 3 subbands (800-720,620-720,540-620 /cm)
c     of band 3 given in table 10.  note that the order of the sub-bands
c     is reversed.
      data gkw/  0.1782,0.0593,0.0215,0.0068,0.0022,0.0000,
     2           0.0923,0.1675,0.0923,0.0187,0.0178,0.0000,
     3           0.0000,0.1083,0.1581,0.0455,0.0274,0.0041/
c-----ne is the number of terms used in each band to compute water vapor
c     continuum transmittance (table 9).
      data ne /0,0,3,1,1,1,1,0,0/
c
c-----coefficients for computing the extinction coefficient
c     for cloud ice particles (table 11a, eq. 6.4a).
c
      data aib /  -0.44171,    0.62951,   0.06465,
     2            -0.13727,    0.61291,   0.28962,
     3            -0.01878,    1.67680,   0.79080,
     4            -0.01896,    1.06510,   0.69493,
     5            -0.04788,    0.88178,   0.54492,
     6            -0.02265,    1.57390,   0.76161,
     7            -0.01038,    2.15640,   0.89045, 
     8            -0.00450,    2.51370,   0.95989,
     9            -0.00044,    3.15050,   1.03750,
     *            -0.02956,    1.44680,   0.71283/
c
c-----coefficients for computing the extinction coefficient
c     for cloud liquid drops. (table 11b, eq. 6.4b)
c
      data awb /   0.08641,    0.01769,    -1.5572e-3,   3.4896e-5,
     2             0.22027,    0.00997,    -1.8719e-3,   5.3112e-5,
     3             0.38074,   -0.03027,     1.0154e-3,  -1.1849e-5,
     4             0.15587,    0.00371,    -7.7705e-4,   2.0547e-5,
     5             0.05518,    0.04544,    -4.2067e-3,   1.0184e-4,
     6             0.12724,    0.04751,    -5.2037e-3,   1.3711e-4,
     7             0.30390,    0.01656,    -3.5271e-3,   1.0828e-4,
     8             0.63617,   -0.06287,     2.2350e-3,  -2.3177e-5,
     9             1.15470,   -0.19282,     1.2084e-2,  -2.5612e-4,
     *             0.34021,   -0.02805,     1.0654e-3,  -1.5443e-5/
c
c-----coefficients for computing the single-scattering albedo
c     for cloud ice particles. (table 12a, eq. 6.5)
c
      data aiw/    0.17201,    1.2229e-2,  -1.4837e-4,   5.8020e-7,
     2             0.81470,   -2.7293e-3,   9.7816e-8,   5.7650e-8,
     3             0.54859,   -4.8273e-4,   5.4353e-6,  -1.5679e-8,
     4             0.39218,    4.1717e-3, - 4.8869e-5,   1.9144e-7,
     5             0.71773,   -3.3640e-3,   1.9713e-5,  -3.3189e-8,
     6             0.77345,   -5.5228e-3,   4.8379e-5,  -1.5151e-7,
     7             0.74975,   -5.6604e-3,   5.6475e-5,  -1.9664e-7,
     8             0.69011,   -4.5348e-3,   4.9322e-5,  -1.8255e-7,
     9             0.83963,   -6.7253e-3,   6.1900e-5,  -2.0862e-7,
     *             0.64860,   -2.8692e-3,   2.7656e-5,  -8.9680e-8/
c
c-----coefficients for computing the single-scattering albedo
c     for cloud liquid drops. (table 12b, eq. 6.5)
c
      data aww/   -7.8566e-2,  8.0875e-2,  -4.3403e-3,   8.1341e-5,
     2            -1.3384e-2,  9.3134e-2,  -6.0491e-3,   1.3059e-4,
     3             3.7096e-2,  7.3211e-2,  -4.4211e-3,   9.2448e-5,
     4            -3.7600e-3,  9.3344e-2,  -5.6561e-3,   1.1387e-4,
     5             0.40212,    7.8083e-2,  -5.9583e-3,   1.2883e-4,
     6             0.57928,    5.9094e-2,  -5.4425e-3,   1.2725e-4,
     7             0.68974,    4.2334e-2,  -4.9469e-3,   1.2863e-4,
     8             0.80122,    9.4578e-3,  -2.8508e-3,   9.0078e-5,
     9             1.02340,   -2.6204e-2,   4.2552e-4,   3.2160e-6,
     *             0.05092,    7.5409e-2,  -4.7305e-3,   1.0121e-4/ 
c
c-----coefficients for computing the asymmetry factor for cloud ice 
c     particles. (table 13a, eq. 6.6)
c
      data aig /   0.57867,    1.0135e-2,  -1.1142e-4,   4.1537e-7,
     2             0.72259,    3.1149e-3,  -1.9927e-5,   5.6024e-8,
     3             0.76109,    4.5449e-3,  -4.6199e-5,   1.6446e-7,
     4             0.86934,    2.7474e-3,  -3.1301e-5,   1.1959e-7,
     5             0.89103,    1.8513e-3,  -1.6551e-5,   5.5193e-8,
     6             0.86325,    2.1408e-3,  -1.6846e-5,   4.9473e-8,
     7             0.85064,    2.5028e-3,  -2.0812e-5,   6.3427e-8,
     8             0.86945,    2.4615e-3,  -2.3882e-5,   8.2431e-8,
     9             0.80122,    3.1906e-3,  -2.4856e-5,   7.2411e-8,
     *             0.73290,    4.8034e-3,  -4.4425e-5,   1.4839e-7/
c
c-----coefficients for computing the asymmetry factor for cloud liquid 
c     drops. (table 13b, eq. 6.6)
c
      data awg /  -0.51930,    0.20290,    -1.1747e-2,   2.3868e-4,
     2            -0.22151,    0.19708,    -1.2462e-2,   2.6646e-4,
     3             0.14157,    0.14705,    -9.5802e-3,   2.0819e-4,
     4             0.41590,    0.10482,    -6.9118e-3,   1.5115e-4,
     5             0.55338,    7.7016e-2,  -5.2218e-3,   1.1587e-4,
     6             0.61384,    6.4402e-2,  -4.6241e-3,   1.0746e-4,
     7             0.67891,    4.8698e-2,  -3.7021e-3,   9.1966e-5,
     8             0.78169,    2.0803e-2,  -1.4749e-3,   3.9362e-5,
     9             0.93218,   -3.3425e-2,   2.9632e-3,  -6.9362e-5,
     *             0.01649,    0.16561,    -1.0723e-2,   2.3220e-4/ 
c
c-----include tables used in the table look-up for co2 (band 3), 
c     o3 (band 5), and h2o (bands 1, 2, and 7) transmission functions.
c     "co2.tran4" is the new co2 transmission table applicable to a large
c     range of co2 amount (up to 100 times of the present-time value).
c     include 'h2o.tran3'
c     include 'co2.tran4'
c     include 'o3.tran3'
      data ((h11(ip,iw),iw=1,31), ip= 1, 1)/
     &   0.99993843,  0.99990183,  0.99985260,  0.99979079,  0.99971771,
     &   0.99963379,  0.99953848,  0.99942899,  0.99930018,  0.99914461,
     &   0.99895102,  0.99870503,  0.99838799,  0.99797899,  0.99745202,
     &   0.99677002,  0.99587703,  0.99469399,  0.99311298,  0.99097902,
     &   0.98807001,  0.98409998,  0.97864997,  0.97114998,  0.96086001,
     &   0.94682997,  0.92777002,  0.90200001,  0.86739999,  0.82169998,
     &   0.76270002/
      data ((h12(ip,iw),iw=1,31), ip= 1, 1)/
     &  -0.2021E-06, -0.3628E-06, -0.5891E-06, -0.8735E-06, -0.1204E-05,
     &  -0.1579E-05, -0.2002E-05, -0.2494E-05, -0.3093E-05, -0.3852E-05,
     &  -0.4835E-05, -0.6082E-05, -0.7591E-05, -0.9332E-05, -0.1128E-04,
     &  -0.1347E-04, -0.1596E-04, -0.1890E-04, -0.2241E-04, -0.2672E-04,
     &  -0.3208E-04, -0.3884E-04, -0.4747E-04, -0.5854E-04, -0.7272E-04,
     &  -0.9092E-04, -0.1146E-03, -0.1458E-03, -0.1877E-03, -0.2435E-03,
     &  -0.3159E-03/
      data ((h13(ip,iw),iw=1,31), ip= 1, 1)/
     &   0.5907E-09,  0.8541E-09,  0.1095E-08,  0.1272E-08,  0.1297E-08,
     &   0.1105E-08,  0.6788E-09, -0.5585E-10, -0.1147E-08, -0.2746E-08,
     &  -0.5001E-08, -0.7715E-08, -0.1037E-07, -0.1227E-07, -0.1287E-07,
     &  -0.1175E-07, -0.8517E-08, -0.2920E-08,  0.4786E-08,  0.1407E-07,
     &   0.2476E-07,  0.3781E-07,  0.5633E-07,  0.8578E-07,  0.1322E-06,
     &   0.2013E-06,  0.3006E-06,  0.4409E-06,  0.6343E-06,  0.8896E-06,
     &   0.1216E-05/
      data ((h11(ip,iw),iw=1,31), ip= 2, 2)/
     &   0.99993837,  0.99990171,  0.99985230,  0.99979031,  0.99971670,
     &   0.99963200,  0.99953520,  0.99942321,  0.99928987,  0.99912637,
     &   0.99892002,  0.99865198,  0.99830002,  0.99783802,  0.99723297,
     &   0.99643701,  0.99537897,  0.99396098,  0.99204701,  0.98944002,
     &   0.98588002,  0.98098999,  0.97425997,  0.96502000,  0.95236999,
     &   0.93515998,  0.91184998,  0.88040000,  0.83859998,  0.78429997,
     &   0.71560001/
      data ((h12(ip,iw),iw=1,31), ip= 2, 2)/
     &  -0.2017E-06, -0.3620E-06, -0.5878E-06, -0.8713E-06, -0.1201E-05,
     &  -0.1572E-05, -0.1991E-05, -0.2476E-05, -0.3063E-05, -0.3808E-05,
     &  -0.4776E-05, -0.6011E-05, -0.7516E-05, -0.9272E-05, -0.1127E-04,
     &  -0.1355E-04, -0.1620E-04, -0.1936E-04, -0.2321E-04, -0.2797E-04,
     &  -0.3399E-04, -0.4171E-04, -0.5172E-04, -0.6471E-04, -0.8150E-04,
     &  -0.1034E-03, -0.1321E-03, -0.1705E-03, -0.2217E-03, -0.2889E-03,
     &  -0.3726E-03/
      data ((h13(ip,iw),iw=1,31), ip= 2, 2)/
     &   0.5894E-09,  0.8519E-09,  0.1092E-08,  0.1267E-08,  0.1289E-08,
     &   0.1093E-08,  0.6601E-09, -0.7831E-10, -0.1167E-08, -0.2732E-08,
     &  -0.4864E-08, -0.7334E-08, -0.9581E-08, -0.1097E-07, -0.1094E-07,
     &  -0.8999E-08, -0.4669E-08,  0.2391E-08,  0.1215E-07,  0.2424E-07,
     &   0.3877E-07,  0.5711E-07,  0.8295E-07,  0.1218E-06,  0.1793E-06,
     &   0.2621E-06,  0.3812E-06,  0.5508E-06,  0.7824E-06,  0.1085E-05,
     &   0.1462E-05/
      data ((h11(ip,iw),iw=1,31), ip= 3, 3)/
     &   0.99993825,  0.99990153,  0.99985188,  0.99978942,  0.99971509,
     &   0.99962920,  0.99953020,  0.99941432,  0.99927431,  0.99909937,
     &   0.99887401,  0.99857497,  0.99817699,  0.99764699,  0.99694097,
     &   0.99599802,  0.99473000,  0.99301600,  0.99068397,  0.98749000,
     &   0.98311001,  0.97707999,  0.96877003,  0.95738000,  0.94186002,
     &   0.92079002,  0.89230001,  0.85420001,  0.80430001,  0.74049997,
     &   0.66200000/
      data ((h12(ip,iw),iw=1,31), ip= 3, 3)/
     &  -0.2011E-06, -0.3609E-06, -0.5859E-06, -0.8680E-06, -0.1195E-05,
     &  -0.1563E-05, -0.1975E-05, -0.2450E-05, -0.3024E-05, -0.3755E-05,
     &  -0.4711E-05, -0.5941E-05, -0.7455E-05, -0.9248E-05, -0.1132E-04,
     &  -0.1373E-04, -0.1659E-04, -0.2004E-04, -0.2431E-04, -0.2966E-04,
     &  -0.3653E-04, -0.4549E-04, -0.5724E-04, -0.7259E-04, -0.9265E-04,
     &  -0.1191E-03, -0.1543E-03, -0.2013E-03, -0.2633E-03, -0.3421E-03,
     &  -0.4350E-03/
      data ((h13(ip,iw),iw=1,31), ip= 3, 3)/
     &   0.5872E-09,  0.8484E-09,  0.1087E-08,  0.1259E-08,  0.1279E-08,
     &   0.1077E-08,  0.6413E-09, -0.9334E-10, -0.1161E-08, -0.2644E-08,
     &  -0.4588E-08, -0.6709E-08, -0.8474E-08, -0.9263E-08, -0.8489E-08,
     &  -0.5553E-08,  0.1203E-09,  0.9035E-08,  0.2135E-07,  0.3689E-07,
     &   0.5610E-07,  0.8097E-07,  0.1155E-06,  0.1649E-06,  0.2350E-06,
     &   0.3353E-06,  0.4806E-06,  0.6858E-06,  0.9617E-06,  0.1315E-05,
     &   0.1741E-05/
      data ((h11(ip,iw),iw=1,31), ip= 4, 4)/
     &   0.99993813,  0.99990118,  0.99985123,  0.99978811,  0.99971271,
     &   0.99962479,  0.99952239,  0.99940068,  0.99925101,  0.99905968,
     &   0.99880803,  0.99846900,  0.99800998,  0.99738997,  0.99655402,
     &   0.99542397,  0.99389100,  0.99180400,  0.98895001,  0.98501998,
     &   0.97961003,  0.97215003,  0.96191001,  0.94791001,  0.92887998,
     &   0.90311998,  0.86849999,  0.82270002,  0.76370001,  0.69000000,
     &   0.60240000/
      data ((h12(ip,iw),iw=1,31), ip= 4, 4)/
     &  -0.2001E-06, -0.3592E-06, -0.5829E-06, -0.8631E-06, -0.1187E-05,
     &  -0.1549E-05, -0.1953E-05, -0.2415E-05, -0.2975E-05, -0.3694E-05,
     &  -0.4645E-05, -0.5882E-05, -0.7425E-05, -0.9279E-05, -0.1147E-04,
     &  -0.1406E-04, -0.1717E-04, -0.2100E-04, -0.2580E-04, -0.3191E-04,
     &  -0.3989E-04, -0.5042E-04, -0.6432E-04, -0.8261E-04, -0.1068E-03,
     &  -0.1389E-03, -0.1820E-03, -0.2391E-03, -0.3127E-03, -0.4021E-03,
     &  -0.5002E-03/
      data ((h13(ip,iw),iw=1,31), ip= 4, 4)/
     &   0.5838E-09,  0.8426E-09,  0.1081E-08,  0.1249E-08,  0.1267E-08,
     &   0.1062E-08,  0.6313E-09, -0.8241E-10, -0.1094E-08, -0.2436E-08,
     &  -0.4100E-08, -0.5786E-08, -0.6992E-08, -0.7083E-08, -0.5405E-08,
     &  -0.1259E-08,  0.6099E-08,  0.1732E-07,  0.3276E-07,  0.5256E-07,
     &   0.7756E-07,  0.1103E-06,  0.1547E-06,  0.2159E-06,  0.3016E-06,
     &   0.4251E-06,  0.6033E-06,  0.8499E-06,  0.1175E-05,  0.1579E-05,
     &   0.2044E-05/
      data ((h11(ip,iw),iw=1,31), ip= 5, 5)/
     &   0.99993789,  0.99990070,  0.99985009,  0.99978602,  0.99970889,
     &   0.99961799,  0.99951053,  0.99938041,  0.99921662,  0.99900270,
     &   0.99871498,  0.99832201,  0.99778402,  0.99704897,  0.99604702,
     &   0.99468100,  0.99281400,  0.99025702,  0.98673999,  0.98189002,
     &   0.97521001,  0.96600002,  0.95337999,  0.93620998,  0.91292000,
     &   0.88150001,  0.83969998,  0.78530002,  0.71650004,  0.63330001,
     &   0.53799999/
      data ((h12(ip,iw),iw=1,31), ip= 5, 5)/
     &  -0.1987E-06, -0.3565E-06, -0.5784E-06, -0.8557E-06, -0.1175E-05,
     &  -0.1530E-05, -0.1923E-05, -0.2372E-05, -0.2919E-05, -0.3631E-05,
     &  -0.4587E-05, -0.5848E-05, -0.7442E-05, -0.9391E-05, -0.1173E-04,
     &  -0.1455E-04, -0.1801E-04, -0.2232E-04, -0.2779E-04, -0.3489E-04,
     &  -0.4428E-04, -0.5678E-04, -0.7333E-04, -0.9530E-04, -0.1246E-03,
     &  -0.1639E-03, -0.2164E-03, -0.2848E-03, -0.3697E-03, -0.4665E-03,
     &  -0.5646E-03/
      data ((h13(ip,iw),iw=1,31), ip= 5, 5)/
     &   0.5785E-09,  0.8338E-09,  0.1071E-08,  0.1239E-08,  0.1256E-08,
     &   0.1057E-08,  0.6480E-09, -0.1793E-10, -0.9278E-09, -0.2051E-08,
     &  -0.3337E-08, -0.4514E-08, -0.5067E-08, -0.4328E-08, -0.1545E-08,
     &   0.4100E-08,  0.1354E-07,  0.2762E-07,  0.4690E-07,  0.7190E-07,
     &   0.1040E-06,  0.1459E-06,  0.2014E-06,  0.2764E-06,  0.3824E-06,
     &   0.5359E-06,  0.7532E-06,  0.1047E-05,  0.1424E-05,  0.1873E-05,
     &   0.2356E-05/
      data ((h11(ip,iw),iw=1,31), ip= 6, 6)/
     &   0.99993753,  0.99989992,  0.99984848,  0.99978292,  0.99970299,
     &   0.99960762,  0.99949282,  0.99935049,  0.99916708,  0.99892199,
     &   0.99858701,  0.99812400,  0.99748403,  0.99660099,  0.99538797,
     &   0.99372399,  0.99143797,  0.98829001,  0.98395002,  0.97794998,
     &   0.96968001,  0.95832998,  0.94283003,  0.92179000,  0.89330000,
     &   0.85530001,  0.80519998,  0.74140000,  0.66280001,  0.57099998,
     &   0.47049999/
      data ((h12(ip,iw),iw=1,31), ip= 6, 6)/
     &  -0.1964E-06, -0.3526E-06, -0.5717E-06, -0.8451E-06, -0.1158E-05,
     &  -0.1504E-05, -0.1886E-05, -0.2322E-05, -0.2861E-05, -0.3576E-05,
     &  -0.4552E-05, -0.5856E-05, -0.7529E-05, -0.9609E-05, -0.1216E-04,
     &  -0.1528E-04, -0.1916E-04, -0.2408E-04, -0.3043E-04, -0.3880E-04,
     &  -0.4997E-04, -0.6488E-04, -0.8474E-04, -0.1113E-03, -0.1471E-03,
     &  -0.1950E-03, -0.2583E-03, -0.3384E-03, -0.4326E-03, -0.5319E-03,
     &  -0.6244E-03/
      data ((h13(ip,iw),iw=1,31), ip= 6, 6)/
     &   0.5713E-09,  0.8263E-09,  0.1060E-08,  0.1226E-08,  0.1252E-08,
     &   0.1076E-08,  0.7149E-09,  0.1379E-09, -0.6043E-09, -0.1417E-08,
     &  -0.2241E-08, -0.2830E-08, -0.2627E-08, -0.8950E-09,  0.3231E-08,
     &   0.1075E-07,  0.2278E-07,  0.4037E-07,  0.6439E-07,  0.9576E-07,
     &   0.1363E-06,  0.1886E-06,  0.2567E-06,  0.3494E-06,  0.4821E-06,
     &   0.6719E-06,  0.9343E-06,  0.1280E-05,  0.1705E-05,  0.2184E-05,
     &   0.2651E-05/
      data ((h11(ip,iw),iw=1,31), ip= 7, 7)/
     &   0.99993700,  0.99989867,  0.99984592,  0.99977797,  0.99969423,
     &   0.99959219,  0.99946660,  0.99930722,  0.99909681,  0.99880999,
     &   0.99841303,  0.99786001,  0.99708802,  0.99601799,  0.99453998,
     &   0.99250001,  0.98969001,  0.98580003,  0.98041999,  0.97299999,
     &   0.96279001,  0.94881999,  0.92980999,  0.90407002,  0.86949998,
     &   0.82370001,  0.76459998,  0.69089997,  0.60310000,  0.50479996,
     &   0.40219998/
      data ((h12(ip,iw),iw=1,31), ip= 7, 7)/
     &  -0.1932E-06, -0.3467E-06, -0.5623E-06, -0.8306E-06, -0.1136E-05,
     &  -0.1472E-05, -0.1842E-05, -0.2269E-05, -0.2807E-05, -0.3539E-05,
     &  -0.4553E-05, -0.5925E-05, -0.7710E-05, -0.9968E-05, -0.1278E-04,
     &  -0.1629E-04, -0.2073E-04, -0.2644E-04, -0.3392E-04, -0.4390E-04,
     &  -0.5727E-04, -0.7516E-04, -0.9916E-04, -0.1315E-03, -0.1752E-03,
     &  -0.2333E-03, -0.3082E-03, -0.3988E-03, -0.4982E-03, -0.5947E-03,
     &  -0.6764E-03/
      data ((h13(ip,iw),iw=1,31), ip= 7, 7)/
     &   0.5612E-09,  0.8116E-09,  0.1048E-08,  0.1222E-08,  0.1270E-08,
     &   0.1141E-08,  0.8732E-09,  0.4336E-09, -0.6548E-10, -0.4774E-09,
     &  -0.7556E-09, -0.6577E-09,  0.4377E-09,  0.3359E-08,  0.9159E-08,
     &   0.1901E-07,  0.3422E-07,  0.5616E-07,  0.8598E-07,  0.1251E-06,
     &   0.1752E-06,  0.2392E-06,  0.3228E-06,  0.4389E-06,  0.6049E-06,
     &   0.8370E-06,  0.1150E-05,  0.1547E-05,  0.2012E-05,  0.2493E-05,
     &   0.2913E-05/
      data ((h11(ip,iw),iw=1,31), ip= 8, 8)/
     &   0.99993622,  0.99989682,  0.99984211,  0.99977070,  0.99968100,
     &   0.99956948,  0.99942881,  0.99924588,  0.99899900,  0.99865800,
     &   0.99818099,  0.99751103,  0.99657297,  0.99526602,  0.99345201,
     &   0.99094099,  0.98746002,  0.98264998,  0.97599000,  0.96682000,
     &   0.95423001,  0.93708003,  0.91380000,  0.88239998,  0.84060001,
     &   0.78610003,  0.71730000,  0.63400000,  0.53859997,  0.43660003,
     &   0.33510000/
      data ((h12(ip,iw),iw=1,31), ip= 8, 8)/
     &  -0.1885E-06, -0.3385E-06, -0.5493E-06, -0.8114E-06, -0.1109E-05,
     &  -0.1436E-05, -0.1796E-05, -0.2219E-05, -0.2770E-05, -0.3535E-05,
     &  -0.4609E-05, -0.6077E-05, -0.8016E-05, -0.1051E-04, -0.1367E-04,
     &  -0.1768E-04, -0.2283E-04, -0.2955E-04, -0.3849E-04, -0.5046E-04,
     &  -0.6653E-04, -0.8813E-04, -0.1173E-03, -0.1569E-03, -0.2100E-03,
     &  -0.2794E-03, -0.3656E-03, -0.4637E-03, -0.5629E-03, -0.6512E-03,
     &  -0.7167E-03/
      data ((h13(ip,iw),iw=1,31), ip= 8, 8)/
     &   0.5477E-09,  0.8000E-09,  0.1039E-08,  0.1234E-08,  0.1331E-08,
     &   0.1295E-08,  0.1160E-08,  0.9178E-09,  0.7535E-09,  0.8301E-09,
     &   0.1184E-08,  0.2082E-08,  0.4253E-08,  0.8646E-08,  0.1650E-07,
     &   0.2920E-07,  0.4834E-07,  0.7564E-07,  0.1125E-06,  0.1606E-06,
     &   0.2216E-06,  0.2992E-06,  0.4031E-06,  0.5493E-06,  0.7549E-06,
     &   0.1035E-05,  0.1400E-05,  0.1843E-05,  0.2327E-05,  0.2774E-05,
     &   0.3143E-05/
      data ((h11(ip,iw),iw=1,31), ip= 9, 9)/
     &   0.99993503,  0.99989408,  0.99983650,  0.99975997,  0.99966192,
     &   0.99953687,  0.99937540,  0.99916059,  0.99886602,  0.99845397,
     &   0.99787402,  0.99705601,  0.99590701,  0.99430102,  0.99206603,
     &   0.98896003,  0.98465002,  0.97869003,  0.97044003,  0.95911002,
     &   0.94363999,  0.92260998,  0.89419997,  0.85609996,  0.80610001,
     &   0.74220002,  0.66359997,  0.57169998,  0.47100002,  0.36860001,
     &   0.27079999/
      data ((h12(ip,iw),iw=1,31), ip= 9, 9)/
     &  -0.1822E-06, -0.3274E-06, -0.5325E-06, -0.7881E-06, -0.1079E-05,
     &  -0.1398E-05, -0.1754E-05, -0.2184E-05, -0.2763E-05, -0.3581E-05,
     &  -0.4739E-05, -0.6341E-05, -0.8484E-05, -0.1128E-04, -0.1490E-04,
     &  -0.1955E-04, -0.2561E-04, -0.3364E-04, -0.4438E-04, -0.5881E-04,
     &  -0.7822E-04, -0.1045E-03, -0.1401E-03, -0.1884E-03, -0.2523E-03,
     &  -0.3335E-03, -0.4289E-03, -0.5296E-03, -0.6231E-03, -0.6980E-03,
     &  -0.7406E-03/
      data ((h13(ip,iw),iw=1,31), ip= 9, 9)/
     &   0.5334E-09,  0.7859E-09,  0.1043E-08,  0.1279E-08,  0.1460E-08,
     &   0.1560E-08,  0.1618E-08,  0.1657E-08,  0.1912E-08,  0.2569E-08,
     &   0.3654E-08,  0.5509E-08,  0.8964E-08,  0.1518E-07,  0.2560E-07,
     &   0.4178E-07,  0.6574E-07,  0.9958E-07,  0.1449E-06,  0.2031E-06,
     &   0.2766E-06,  0.3718E-06,  0.5022E-06,  0.6849E-06,  0.9360E-06,
     &   0.1268E-05,  0.1683E-05,  0.2157E-05,  0.2625E-05,  0.3020E-05,
     &   0.3364E-05/
      data ((h11(ip,iw),iw=1,31), ip=10,10)/
     &   0.99993336,  0.99989021,  0.99982840,  0.99974459,  0.99963468,
     &   0.99949121,  0.99930137,  0.99904430,  0.99868703,  0.99818403,
     &   0.99747300,  0.99646801,  0.99505299,  0.99307102,  0.99030602,
     &   0.98645997,  0.98111999,  0.97372001,  0.96353000,  0.94957000,
     &   0.93058997,  0.90486002,  0.87029999,  0.82449996,  0.76530004,
     &   0.69159997,  0.60380000,  0.50529999,  0.40259999,  0.30269998,
     &   0.21020001/
      data ((h12(ip,iw),iw=1,31), ip=10,10)/
     &  -0.1742E-06, -0.3134E-06, -0.5121E-06, -0.7619E-06, -0.1048E-05,
     &  -0.1364E-05, -0.1725E-05, -0.2177E-05, -0.2801E-05, -0.3694E-05,
     &  -0.4969E-05, -0.6748E-05, -0.9161E-05, -0.1236E-04, -0.1655E-04,
     &  -0.2203E-04, -0.2927E-04, -0.3894E-04, -0.5192E-04, -0.6936E-04,
     &  -0.9294E-04, -0.1250E-03, -0.1686E-03, -0.2271E-03, -0.3027E-03,
     &  -0.3944E-03, -0.4951E-03, -0.5928E-03, -0.6755E-03, -0.7309E-03,
     &  -0.7417E-03/
      data ((h13(ip,iw),iw=1,31), ip=10,10)/
     &   0.5179E-09,  0.7789E-09,  0.1071E-08,  0.1382E-08,  0.1690E-08,
     &   0.1979E-08,  0.2297E-08,  0.2704E-08,  0.3466E-08,  0.4794E-08,
     &   0.6746E-08,  0.9739E-08,  0.1481E-07,  0.2331E-07,  0.3679E-07,
     &   0.5726E-07,  0.8716E-07,  0.1289E-06,  0.1837E-06,  0.2534E-06,
     &   0.3424E-06,  0.4609E-06,  0.6245E-06,  0.8495E-06,  0.1151E-05,
     &   0.1536E-05,  0.1991E-05,  0.2468E-05,  0.2891E-05,  0.3245E-05,
     &   0.3580E-05/
      data ((h11(ip,iw),iw=1,31), ip=11,11)/
     &   0.99993110,  0.99988490,  0.99981719,  0.99972337,  0.99959719,
     &   0.99942869,  0.99920130,  0.99888903,  0.99845201,  0.99783301,
     &   0.99695599,  0.99571502,  0.99396503,  0.99150997,  0.98808002,
     &   0.98329997,  0.97667003,  0.96750998,  0.95494002,  0.93779999,
     &   0.91453999,  0.88319999,  0.84130001,  0.78689998,  0.71799999,
     &   0.63470000,  0.53909999,  0.43699998,  0.33550000,  0.24010003,
     &   0.15420002/
      data ((h12(ip,iw),iw=1,31), ip=11,11)/
     &  -0.1647E-06, -0.2974E-06, -0.4900E-06, -0.7358E-06, -0.1022E-05,
     &  -0.1344E-05, -0.1721E-05, -0.2212E-05, -0.2901E-05, -0.3896E-05,
     &  -0.5327E-05, -0.7342E-05, -0.1011E-04, -0.1382E-04, -0.1875E-04,
     &  -0.2530E-04, -0.3403E-04, -0.4573E-04, -0.6145E-04, -0.8264E-04,
     &  -0.1114E-03, -0.1507E-03, -0.2039E-03, -0.2737E-03, -0.3607E-03,
     &  -0.4599E-03, -0.5604E-03, -0.6497E-03, -0.7161E-03, -0.7443E-03,
     &  -0.7133E-03/
      data ((h13(ip,iw),iw=1,31), ip=11,11)/
     &   0.5073E-09,  0.7906E-09,  0.1134E-08,  0.1560E-08,  0.2046E-08,
     &   0.2589E-08,  0.3254E-08,  0.4107E-08,  0.5481E-08,  0.7602E-08,
     &   0.1059E-07,  0.1501E-07,  0.2210E-07,  0.3334E-07,  0.5055E-07,
     &   0.7629E-07,  0.1134E-06,  0.1642E-06,  0.2298E-06,  0.3133E-06,
     &   0.4225E-06,  0.5709E-06,  0.7739E-06,  0.1047E-05,  0.1401E-05,
     &   0.1833E-05,  0.2308E-05,  0.2753E-05,  0.3125E-05,  0.3467E-05,
     &   0.3748E-05/
      data ((h11(ip,iw),iw=1,31), ip=12,12)/
     &   0.99992824,  0.99987793,  0.99980247,  0.99969512,  0.99954712,
     &   0.99934530,  0.99906880,  0.99868500,  0.99814498,  0.99738002,
     &   0.99629498,  0.99475700,  0.99258602,  0.98953998,  0.98527998,
     &   0.97934997,  0.97112000,  0.95981002,  0.94433999,  0.92332000,
     &   0.89490002,  0.85680002,  0.80680001,  0.74290001,  0.66420001,
     &   0.57220000,  0.47149998,  0.36900002,  0.27109998,  0.18159997,
     &   0.10460001/
      data ((h12(ip,iw),iw=1,31), ip=12,12)/
     &  -0.1548E-06, -0.2808E-06, -0.4683E-06, -0.7142E-06, -0.1008E-05,
     &  -0.1347E-05, -0.1758E-05, -0.2306E-05, -0.3083E-05, -0.4214E-05,
     &  -0.5851E-05, -0.8175E-05, -0.1140E-04, -0.1577E-04, -0.2166E-04,
     &  -0.2955E-04, -0.4014E-04, -0.5434E-04, -0.7343E-04, -0.9931E-04,
     &  -0.1346E-03, -0.1826E-03, -0.2467E-03, -0.3283E-03, -0.4246E-03,
     &  -0.5264E-03, -0.6211E-03, -0.6970E-03, -0.7402E-03, -0.7316E-03,
     &  -0.6486E-03/
      data ((h13(ip,iw),iw=1,31), ip=12,12)/
     &   0.5078E-09,  0.8244E-09,  0.1255E-08,  0.1826E-08,  0.2550E-08,
     &   0.3438E-08,  0.4532E-08,  0.5949E-08,  0.8041E-08,  0.1110E-07,
     &   0.1534E-07,  0.2157E-07,  0.3116E-07,  0.4570E-07,  0.6747E-07,
     &   0.9961E-07,  0.1451E-06,  0.2061E-06,  0.2843E-06,  0.3855E-06,
     &   0.5213E-06,  0.7060E-06,  0.9544E-06,  0.1280E-05,  0.1684E-05,
     &   0.2148E-05,  0.2609E-05,  0.3002E-05,  0.3349E-05,  0.3670E-05,
     &   0.3780E-05/
      data ((h11(ip,iw),iw=1,31), ip=13,13)/
     &   0.99992472,  0.99986941,  0.99978399,  0.99965900,  0.99948251,
     &   0.99923742,  0.99889702,  0.99842298,  0.99775398,  0.99680400,
     &   0.99545598,  0.99354500,  0.99084800,  0.98706001,  0.98176998,
     &   0.97439998,  0.96423000,  0.95029002,  0.93129998,  0.90557003,
     &   0.87099999,  0.82520002,  0.76600003,  0.69220001,  0.60440004,
     &   0.50580001,  0.40310001,  0.30299997,  0.21039999,  0.12860000,
     &   0.06360000/
      data ((h12(ip,iw),iw=1,31), ip=13,13)/
     &  -0.1461E-06, -0.2663E-06, -0.4512E-06, -0.7027E-06, -0.1014E-05,
     &  -0.1387E-05, -0.1851E-05, -0.2478E-05, -0.3373E-05, -0.4682E-05,
     &  -0.6588E-05, -0.9311E-05, -0.1311E-04, -0.1834E-04, -0.2544E-04,
     &  -0.3502E-04, -0.4789E-04, -0.6515E-04, -0.8846E-04, -0.1202E-03,
     &  -0.1635E-03, -0.2217E-03, -0.2975E-03, -0.3897E-03, -0.4913E-03,
     &  -0.5902E-03, -0.6740E-03, -0.7302E-03, -0.7415E-03, -0.6858E-03,
     &  -0.5447E-03/
      data ((h13(ip,iw),iw=1,31), ip=13,13)/
     &   0.5236E-09,  0.8873E-09,  0.1426E-08,  0.2193E-08,  0.3230E-08,
     &   0.4555E-08,  0.6200E-08,  0.8298E-08,  0.1126E-07,  0.1544E-07,
     &   0.2130E-07,  0.2978E-07,  0.4239E-07,  0.6096E-07,  0.8829E-07,
     &   0.1280E-06,  0.1830E-06,  0.2555E-06,  0.3493E-06,  0.4740E-06,
     &   0.6431E-06,  0.8701E-06,  0.1169E-05,  0.1547E-05,  0.1992E-05,
     &   0.2460E-05,  0.2877E-05,  0.3230E-05,  0.3569E-05,  0.3782E-05,
     &   0.3591E-05/
      data ((h11(ip,iw),iw=1,31), ip=14,14)/
     &   0.99992090,  0.99985969,  0.99976218,  0.99961531,  0.99940270,
     &   0.99910218,  0.99868101,  0.99809098,  0.99725902,  0.99607700,
     &   0.99440002,  0.99202299,  0.98866999,  0.98395997,  0.97737998,
     &   0.96825999,  0.95570999,  0.93857002,  0.91531003,  0.88389999,
     &   0.84210002,  0.78759998,  0.71869999,  0.63530004,  0.53970003,
     &   0.43750000,  0.33590001,  0.24040002,  0.15439999,  0.08300000,
     &   0.03299999/
      data ((h12(ip,iw),iw=1,31), ip=14,14)/
     &  -0.1402E-06, -0.2569E-06, -0.4428E-06, -0.7076E-06, -0.1051E-05,
     &  -0.1478E-05, -0.2019E-05, -0.2752E-05, -0.3802E-05, -0.5343E-05,
     &  -0.7594E-05, -0.1082E-04, -0.1536E-04, -0.2166E-04, -0.3028E-04,
     &  -0.4195E-04, -0.5761E-04, -0.7867E-04, -0.1072E-03, -0.1462E-03,
     &  -0.1990E-03, -0.2687E-03, -0.3559E-03, -0.4558E-03, -0.5572E-03,
     &  -0.6476E-03, -0.7150E-03, -0.7439E-03, -0.7133E-03, -0.6015E-03,
     &  -0.4089E-03/
      data ((h13(ip,iw),iw=1,31), ip=14,14)/
     &   0.5531E-09,  0.9757E-09,  0.1644E-08,  0.2650E-08,  0.4074E-08,
     &   0.5957E-08,  0.8314E-08,  0.1128E-07,  0.1528E-07,  0.2087E-07,
     &   0.2874E-07,  0.4002E-07,  0.5631E-07,  0.7981E-07,  0.1139E-06,
     &   0.1621E-06,  0.2275E-06,  0.3136E-06,  0.4280E-06,  0.5829E-06,
     &   0.7917E-06,  0.1067E-05,  0.1419E-05,  0.1844E-05,  0.2310E-05,
     &   0.2747E-05,  0.3113E-05,  0.3455E-05,  0.3739E-05,  0.3715E-05,
     &   0.3125E-05/
      data ((h11(ip,iw),iw=1,31), ip=15,15)/
     &   0.99991709,  0.99984968,  0.99973857,  0.99956548,  0.99930853,
     &   0.99893898,  0.99841601,  0.99768001,  0.99664098,  0.99516898,
     &   0.99308002,  0.99012297,  0.98594999,  0.98009998,  0.97194999,
     &   0.96066999,  0.94523001,  0.92421001,  0.89579999,  0.85769999,
     &   0.80760002,  0.74360001,  0.66490000,  0.57290000,  0.47200000,
     &   0.36940002,  0.27139997,  0.18180001,  0.10479999,  0.04699999,
     &   0.01359999/
      data ((h12(ip,iw),iw=1,31), ip=15,15)/
     &  -0.1378E-06, -0.2542E-06, -0.4461E-06, -0.7333E-06, -0.1125E-05,
     &  -0.1630E-05, -0.2281E-05, -0.3159E-05, -0.4410E-05, -0.6246E-05,
     &  -0.8933E-05, -0.1280E-04, -0.1826E-04, -0.2589E-04, -0.3639E-04,
     &  -0.5059E-04, -0.6970E-04, -0.9552E-04, -0.1307E-03, -0.1784E-03,
     &  -0.2422E-03, -0.3237E-03, -0.4203E-03, -0.5227E-03, -0.6184E-03,
     &  -0.6953E-03, -0.7395E-03, -0.7315E-03, -0.6487E-03, -0.4799E-03,
     &  -0.2625E-03/
      data ((h13(ip,iw),iw=1,31), ip=15,15)/
     &   0.5891E-09,  0.1074E-08,  0.1885E-08,  0.3167E-08,  0.5051E-08,
     &   0.7631E-08,  0.1092E-07,  0.1500E-07,  0.2032E-07,  0.2769E-07,
     &   0.3810E-07,  0.5279E-07,  0.7361E-07,  0.1032E-06,  0.1450E-06,
     &   0.2026E-06,  0.2798E-06,  0.3832E-06,  0.5242E-06,  0.7159E-06,
     &   0.9706E-06,  0.1299E-05,  0.1701E-05,  0.2159E-05,  0.2612E-05,
     &   0.2998E-05,  0.3341E-05,  0.3661E-05,  0.3775E-05,  0.3393E-05,
     &   0.2384E-05/
      data ((h11(ip,iw),iw=1,31), ip=16,16)/
     &   0.99991363,  0.99984020,  0.99971467,  0.99951237,  0.99920303,
     &   0.99874902,  0.99809903,  0.99717999,  0.99588197,  0.99404502,
     &   0.99144298,  0.98776001,  0.98258001,  0.97533000,  0.96524000,
     &   0.95135999,  0.93241000,  0.90667999,  0.87199998,  0.82620001,
     &   0.76700002,  0.69309998,  0.60510004,  0.50650001,  0.40359998,
     &   0.30350000,  0.21069998,  0.12870002,  0.06370002,  0.02200001,
     &   0.00389999/
      data ((h12(ip,iw),iw=1,31), ip=16,16)/
     &  -0.1383E-06, -0.2577E-06, -0.4608E-06, -0.7793E-06, -0.1237E-05,
     &  -0.1850E-05, -0.2652E-05, -0.3728E-05, -0.5244E-05, -0.7451E-05,
     &  -0.1067E-04, -0.1532E-04, -0.2193E-04, -0.3119E-04, -0.4395E-04,
     &  -0.6126E-04, -0.8466E-04, -0.1164E-03, -0.1596E-03, -0.2177E-03,
     &  -0.2933E-03, -0.3855E-03, -0.4874E-03, -0.5870E-03, -0.6718E-03,
     &  -0.7290E-03, -0.7411E-03, -0.6859E-03, -0.5450E-03, -0.3353E-03,
     &  -0.1363E-03/
      data ((h13(ip,iw),iw=1,31), ip=16,16)/
     &   0.6217E-09,  0.1165E-08,  0.2116E-08,  0.3685E-08,  0.6101E-08,
     &   0.9523E-08,  0.1400E-07,  0.1959E-07,  0.2668E-07,  0.3629E-07,
     &   0.4982E-07,  0.6876E-07,  0.9523E-07,  0.1321E-06,  0.1825E-06,
     &   0.2505E-06,  0.3420E-06,  0.4677E-06,  0.6416E-06,  0.8760E-06,
     &   0.1183E-05,  0.1565E-05,  0.2010E-05,  0.2472E-05,  0.2882E-05,
     &   0.3229E-05,  0.3564E-05,  0.3777E-05,  0.3589E-05,  0.2786E-05,
     &   0.1487E-05/
      data ((h11(ip,iw),iw=1,31), ip=17,17)/
     &   0.99991077,  0.99983180,  0.99969262,  0.99945968,  0.99909151,
     &   0.99853700,  0.99773198,  0.99658400,  0.99496001,  0.99266702,
     &   0.98943001,  0.98484999,  0.97842997,  0.96945000,  0.95703000,
     &   0.93998998,  0.91676998,  0.88540000,  0.84350002,  0.78890002,
     &   0.71990001,  0.63639998,  0.54060000,  0.43820000,  0.33639997,
     &   0.24080002,  0.15460002,  0.08310002,  0.03310001,  0.00770003,
     &   0.00050002/
      data ((h12(ip,iw),iw=1,31), ip=17,17)/
     &  -0.1405E-06, -0.2649E-06, -0.4829E-06, -0.8398E-06, -0.1379E-05,
     &  -0.2132E-05, -0.3138E-05, -0.4487E-05, -0.6353E-05, -0.9026E-05,
     &  -0.1290E-04, -0.1851E-04, -0.2650E-04, -0.3772E-04, -0.5319E-04,
     &  -0.7431E-04, -0.1031E-03, -0.1422E-03, -0.1951E-03, -0.2648E-03,
     &  -0.3519E-03, -0.4518E-03, -0.5537E-03, -0.6449E-03, -0.7133E-03,
     &  -0.7432E-03, -0.7133E-03, -0.6018E-03, -0.4092E-03, -0.1951E-03,
     &  -0.5345E-04/
      data ((h13(ip,iw),iw=1,31), ip=17,17)/
     &   0.6457E-09,  0.1235E-08,  0.2303E-08,  0.4149E-08,  0.7120E-08,
     &   0.1152E-07,  0.1749E-07,  0.2508E-07,  0.3462E-07,  0.4718E-07,
     &   0.6452E-07,  0.8874E-07,  0.1222E-06,  0.1675E-06,  0.2276E-06,
     &   0.3076E-06,  0.4174E-06,  0.5714E-06,  0.7837E-06,  0.1067E-05,
     &   0.1428E-05,  0.1859E-05,  0.2327E-05,  0.2760E-05,  0.3122E-05,
     &   0.3458E-05,  0.3739E-05,  0.3715E-05,  0.3126E-05,  0.1942E-05,
     &   0.6977E-06/
      data ((h11(ip,iw),iw=1,31), ip=18,18)/
     &   0.99990851,  0.99982500,  0.99967349,  0.99941093,  0.99897999,
     &   0.99831200,  0.99732101,  0.99589097,  0.99386197,  0.99099803,
     &   0.98695999,  0.98128998,  0.97333002,  0.96227002,  0.94700998,
     &   0.92614001,  0.89779997,  0.85969996,  0.80949998,  0.74540001,
     &   0.66649997,  0.57420003,  0.47310001,  0.37029999,  0.27200001,
     &   0.18220001,  0.10500002,  0.04710001,  0.01359999,  0.00169998,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=18,18)/
     &  -0.1431E-06, -0.2731E-06, -0.5072E-06, -0.9057E-06, -0.1537E-05,
     &  -0.2460E-05, -0.3733E-05, -0.5449E-05, -0.7786E-05, -0.1106E-04,
     &  -0.1574E-04, -0.2249E-04, -0.3212E-04, -0.4564E-04, -0.6438E-04,
     &  -0.9019E-04, -0.1256E-03, -0.1737E-03, -0.2378E-03, -0.3196E-03,
     &  -0.4163E-03, -0.5191E-03, -0.6154E-03, -0.6931E-03, -0.7384E-03,
     &  -0.7313E-03, -0.6492E-03, -0.4805E-03, -0.2629E-03, -0.8897E-04,
     &  -0.1432E-04/
      data ((h13(ip,iw),iw=1,31), ip=18,18)/
     &   0.6607E-09,  0.1282E-08,  0.2441E-08,  0.4522E-08,  0.8027E-08,
     &   0.1348E-07,  0.2122E-07,  0.3139E-07,  0.4435E-07,  0.6095E-07,
     &   0.8319E-07,  0.1139E-06,  0.1557E-06,  0.2107E-06,  0.2819E-06,
     &   0.3773E-06,  0.5107E-06,  0.6982E-06,  0.9542E-06,  0.1290E-05,
     &   0.1703E-05,  0.2170E-05,  0.2628E-05,  0.3013E-05,  0.3352E-05,
     &   0.3669E-05,  0.3780E-05,  0.3397E-05,  0.2386E-05,  0.1062E-05,
     &   0.2216E-06/
      data ((h11(ip,iw),iw=1,31), ip=19,19)/
     &   0.99990678,  0.99981970,  0.99965781,  0.99936831,  0.99887598,
     &   0.99808502,  0.99687898,  0.99510998,  0.99257898,  0.98900002,
     &   0.98398000,  0.97693998,  0.96711999,  0.95353001,  0.93484998,
     &   0.90934002,  0.87479997,  0.82900000,  0.76960003,  0.69550002,
     &   0.60720003,  0.50819999,  0.40490001,  0.30440003,  0.21130002,
     &   0.12910002,  0.06389999,  0.02200001,  0.00389999,  0.00010002,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=19,19)/
     &  -0.1454E-06, -0.2805E-06, -0.5296E-06, -0.9685E-06, -0.1695E-05,
     &  -0.2812E-05, -0.4412E-05, -0.6606E-05, -0.9573E-05, -0.1363E-04,
     &  -0.1932E-04, -0.2743E-04, -0.3897E-04, -0.5520E-04, -0.7787E-04,
     &  -0.1094E-03, -0.1529E-03, -0.2117E-03, -0.2880E-03, -0.3809E-03,
     &  -0.4834E-03, -0.5836E-03, -0.6692E-03, -0.7275E-03, -0.7408E-03,
     &  -0.6865E-03, -0.5459E-03, -0.3360E-03, -0.1365E-03, -0.2935E-04,
     &  -0.2173E-05/
      data ((h13(ip,iw),iw=1,31), ip=19,19)/
     &   0.6693E-09,  0.1312E-08,  0.2538E-08,  0.4802E-08,  0.8778E-08,
     &   0.1528E-07,  0.2501E-07,  0.3836E-07,  0.5578E-07,  0.7806E-07,
     &   0.1069E-06,  0.1456E-06,  0.1970E-06,  0.2631E-06,  0.3485E-06,
     &   0.4642E-06,  0.6268E-06,  0.8526E-06,  0.1157E-05,  0.1545E-05,
     &   0.2002E-05,  0.2478E-05,  0.2897E-05,  0.3245E-05,  0.3578E-05,
     &   0.3789E-05,  0.3598E-05,  0.2792E-05,  0.1489E-05,  0.4160E-06,
     &   0.3843E-07/
      data ((h11(ip,iw),iw=1,31), ip=20,20)/
     &   0.99990559,  0.99981570,  0.99964547,  0.99933308,  0.99878299,
     &   0.99786699,  0.99642301,  0.99425799,  0.99111998,  0.98667002,
     &   0.98041999,  0.97170001,  0.95960999,  0.94295001,  0.92012000,
     &   0.88900000,  0.84740001,  0.79280001,  0.72360003,  0.63960004,
     &   0.54330003,  0.44029999,  0.33800000,  0.24190003,  0.15530002,
     &   0.08350003,  0.03320003,  0.00770003,  0.00050002,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=20,20)/
     &  -0.1472E-06, -0.2866E-06, -0.5485E-06, -0.1024E-05, -0.1842E-05,
     &  -0.3160E-05, -0.5136E-05, -0.7922E-05, -0.1171E-04, -0.1682E-04,
     &  -0.2381E-04, -0.3355E-04, -0.4729E-04, -0.6673E-04, -0.9417E-04,
     &  -0.1327E-03, -0.1858E-03, -0.2564E-03, -0.3449E-03, -0.4463E-03,
     &  -0.5495E-03, -0.6420E-03, -0.7116E-03, -0.7427E-03, -0.7139E-03,
     &  -0.6031E-03, -0.4104E-03, -0.1957E-03, -0.5358E-04, -0.6176E-05,
     &  -0.1347E-06/
      data ((h13(ip,iw),iw=1,31), ip=20,20)/
     &   0.6750E-09,  0.1332E-08,  0.2602E-08,  0.5003E-08,  0.9367E-08,
     &   0.1684E-07,  0.2863E-07,  0.4566E-07,  0.6865E-07,  0.9861E-07,
     &   0.1368E-06,  0.1856E-06,  0.2479E-06,  0.3274E-06,  0.4315E-06,
     &   0.5739E-06,  0.7710E-06,  0.1040E-05,  0.1394E-05,  0.1829E-05,
     &   0.2309E-05,  0.2759E-05,  0.3131E-05,  0.3472E-05,  0.3755E-05,
     &   0.3730E-05,  0.3138E-05,  0.1948E-05,  0.6994E-06,  0.1022E-06,
     &   0.2459E-08/
      data ((h11(ip,iw),iw=1,31), ip=21,21)/
     &   0.99990469,  0.99981278,  0.99963617,  0.99930513,  0.99870503,
     &   0.99766999,  0.99597800,  0.99336702,  0.98951000,  0.98399001,
     &   0.97622001,  0.96543998,  0.95059001,  0.93019998,  0.90235001,
     &   0.86470002,  0.81480002,  0.75059998,  0.67129999,  0.57840002,
     &   0.47659999,  0.37279999,  0.27389997,  0.18339998,  0.10570002,
     &   0.04740000,  0.01370001,  0.00169998,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=21,21)/
     &  -0.1487E-06, -0.2912E-06, -0.5636E-06, -0.1069E-05, -0.1969E-05,
     &  -0.3483E-05, -0.5858E-05, -0.9334E-05, -0.1416E-04, -0.2067E-04,
     &  -0.2936E-04, -0.4113E-04, -0.5750E-04, -0.8072E-04, -0.1139E-03,
     &  -0.1606E-03, -0.2246E-03, -0.3076E-03, -0.4067E-03, -0.5121E-03,
     &  -0.6110E-03, -0.6909E-03, -0.7378E-03, -0.7321E-03, -0.6509E-03,
     &  -0.4825E-03, -0.2641E-03, -0.8936E-04, -0.1436E-04, -0.5966E-06,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=21,21)/
     &   0.6777E-09,  0.1344E-08,  0.2643E-08,  0.5138E-08,  0.9798E-08,
     &   0.1809E-07,  0.3185E-07,  0.5285E-07,  0.8249E-07,  0.1222E-06,
     &   0.1730E-06,  0.2351E-06,  0.3111E-06,  0.4078E-06,  0.5366E-06,
     &   0.7117E-06,  0.9495E-06,  0.1266E-05,  0.1667E-05,  0.2132E-05,
     &   0.2600E-05,  0.3001E-05,  0.3354E-05,  0.3679E-05,  0.3796E-05,
     &   0.3414E-05,  0.2399E-05,  0.1067E-05,  0.2222E-06,  0.1075E-07,
     &   0.0000E+00/
      data ((h11(ip,iw),iw=1,31), ip=22,22)/
     &   0.99990410,  0.99981070,  0.99962938,  0.99928379,  0.99864298,
     &   0.99750000,  0.99556601,  0.99247700,  0.98780000,  0.98100001,
     &   0.97140002,  0.95810002,  0.93984997,  0.91491997,  0.88110000,
     &   0.83570004,  0.77670002,  0.70239997,  0.61350000,  0.51349998,
     &   0.40910000,  0.30750000,  0.21340001,  0.13040000,  0.06449997,
     &   0.02219999,  0.00389999,  0.00010002,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=22,22)/
     &  -0.1496E-06, -0.2947E-06, -0.5749E-06, -0.1105E-05, -0.2074E-05,
     &  -0.3763E-05, -0.6531E-05, -0.1076E-04, -0.1682E-04, -0.2509E-04,
     &  -0.3605E-04, -0.5049E-04, -0.7012E-04, -0.9787E-04, -0.1378E-03,
     &  -0.1939E-03, -0.2695E-03, -0.3641E-03, -0.4703E-03, -0.5750E-03,
     &  -0.6648E-03, -0.7264E-03, -0.7419E-03, -0.6889E-03, -0.5488E-03,
     &  -0.3382E-03, -0.1375E-03, -0.2951E-04, -0.2174E-05,  0.0000E+00,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=22,22)/
     &   0.6798E-09,  0.1350E-08,  0.2667E-08,  0.5226E-08,  0.1010E-07,
     &   0.1903E-07,  0.3455E-07,  0.5951E-07,  0.9658E-07,  0.1479E-06,
     &   0.2146E-06,  0.2951E-06,  0.3903E-06,  0.5101E-06,  0.6693E-06,
     &   0.8830E-06,  0.1168E-05,  0.1532E-05,  0.1968E-05,  0.2435E-05,
     &   0.2859E-05,  0.3222E-05,  0.3572E-05,  0.3797E-05,  0.3615E-05,
     &   0.2811E-05,  0.1500E-05,  0.4185E-06,  0.3850E-07,  0.0000E+00,
     &   0.0000E+00/
      data ((h11(ip,iw),iw=1,31), ip=23,23)/
     &   0.99990374,  0.99980932,  0.99962449,  0.99926788,  0.99859399,
     &   0.99736100,  0.99520397,  0.99163198,  0.98606002,  0.97779000,
     &   0.96600002,  0.94963002,  0.92720997,  0.89670002,  0.85580003,
     &   0.80170000,  0.73269999,  0.64840001,  0.55110002,  0.44669998,
     &   0.34280002,  0.24529999,  0.15750003,  0.08469999,  0.03369999,
     &   0.00779998,  0.00050002,  0.00000000,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=23,23)/
     &  -0.1503E-06, -0.2971E-06, -0.5832E-06, -0.1131E-05, -0.2154E-05,
     &  -0.3992E-05, -0.7122E-05, -0.1211E-04, -0.1954E-04, -0.2995E-04,
     &  -0.4380E-04, -0.6183E-04, -0.8577E-04, -0.1191E-03, -0.1668E-03,
     &  -0.2333E-03, -0.3203E-03, -0.4237E-03, -0.5324E-03, -0.6318E-03,
     &  -0.7075E-03, -0.7429E-03, -0.7168E-03, -0.6071E-03, -0.4139E-03,
     &  -0.1976E-03, -0.5410E-04, -0.6215E-05, -0.1343E-06,  0.0000E+00,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=23,23)/
     &   0.6809E-09,  0.1356E-08,  0.2683E-08,  0.5287E-08,  0.1030E-07,
     &   0.1971E-07,  0.3665E-07,  0.6528E-07,  0.1100E-06,  0.1744E-06,
     &   0.2599E-06,  0.3650E-06,  0.4887E-06,  0.6398E-06,  0.8358E-06,
     &   0.1095E-05,  0.1429E-05,  0.1836E-05,  0.2286E-05,  0.2716E-05,
     &   0.3088E-05,  0.3444E-05,  0.3748E-05,  0.3740E-05,  0.3157E-05,
     &   0.1966E-05,  0.7064E-06,  0.1030E-06,  0.2456E-08,  0.0000E+00,
     &   0.0000E+00/
      data ((h11(ip,iw),iw=1,31), ip=24,24)/
     &   0.99990344,  0.99980831,  0.99962109,  0.99925637,  0.99855798,
     &   0.99725199,  0.99489999,  0.99087203,  0.98436999,  0.97447002,
     &   0.96012998,  0.94006002,  0.91254002,  0.87540001,  0.82609999,
     &   0.76240003,  0.68299997,  0.58930004,  0.48589998,  0.38020003,
     &   0.27920002,  0.18699998,  0.10769999,  0.04830003,  0.01400000,
     &   0.00169998,  0.00000000,  0.00000000,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=24,24)/
     &  -0.1508E-06, -0.2989E-06, -0.5892E-06, -0.1151E-05, -0.2216E-05,
     &  -0.4175E-05, -0.7619E-05, -0.1333E-04, -0.2217E-04, -0.3497E-04,
     &  -0.5238E-04, -0.7513E-04, -0.1049E-03, -0.1455E-03, -0.2021E-03,
     &  -0.2790E-03, -0.3757E-03, -0.4839E-03, -0.5902E-03, -0.6794E-03,
     &  -0.7344E-03, -0.7341E-03, -0.6557E-03, -0.4874E-03, -0.2674E-03,
     &  -0.9059E-04, -0.1455E-04, -0.5986E-06,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=24,24)/
     &   0.6812E-09,  0.1356E-08,  0.2693E-08,  0.5328E-08,  0.1045E-07,
     &   0.2021E-07,  0.3826E-07,  0.6994E-07,  0.1218E-06,  0.1997E-06,
     &   0.3069E-06,  0.4428E-06,  0.6064E-06,  0.8015E-06,  0.1043E-05,
     &   0.1351E-05,  0.1733E-05,  0.2168E-05,  0.2598E-05,  0.2968E-05,
     &   0.3316E-05,  0.3662E-05,  0.3801E-05,  0.3433E-05,  0.2422E-05,
     &   0.1081E-05,  0.2256E-06,  0.1082E-07,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h11(ip,iw),iw=1,31), ip=25,25)/
     &   0.99990326,  0.99980772,  0.99961871,  0.99924821,  0.99853098,
     &   0.99716800,  0.99465698,  0.99022102,  0.98281002,  0.97118002,
     &   0.95393997,  0.92948997,  0.89579999,  0.85070002,  0.79189998,
     &   0.71759999,  0.62800002,  0.52639997,  0.41970003,  0.31559998,
     &   0.21899998,  0.13370001,  0.06610000,  0.02280003,  0.00400001,
     &   0.00010002,  0.00000000,  0.00000000,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=25,25)/
     &  -0.1511E-06, -0.3001E-06, -0.5934E-06, -0.1166E-05, -0.2263E-05,
     &  -0.4319E-05, -0.8028E-05, -0.1438E-04, -0.2460E-04, -0.3991E-04,
     &  -0.6138E-04, -0.9005E-04, -0.1278E-03, -0.1778E-03, -0.2447E-03,
     &  -0.3313E-03, -0.4342E-03, -0.5424E-03, -0.6416E-03, -0.7146E-03,
     &  -0.7399E-03, -0.6932E-03, -0.5551E-03, -0.3432E-03, -0.1398E-03,
     &  -0.3010E-04, -0.2229E-05,  0.0000E+00,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=25,25)/
     &   0.6815E-09,  0.1358E-08,  0.2698E-08,  0.5355E-08,  0.1054E-07,
     &   0.2056E-07,  0.3942E-07,  0.7349E-07,  0.1315E-06,  0.2226E-06,
     &   0.3537E-06,  0.5266E-06,  0.7407E-06,  0.9958E-06,  0.1296E-05,
     &   0.1657E-05,  0.2077E-05,  0.2512E-05,  0.2893E-05,  0.3216E-05,
     &   0.3562E-05,  0.3811E-05,  0.3644E-05,  0.2841E-05,  0.1524E-05,
     &   0.4276E-06,  0.3960E-07,  0.0000E+00,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h11(ip,iw),iw=1,31), ip=26,26)/
     &   0.99990320,  0.99980718,  0.99961710,  0.99924242,  0.99851102,
     &   0.99710602,  0.99446702,  0.98969001,  0.98144001,  0.96805000,
     &   0.94762999,  0.91812998,  0.87730002,  0.82290000,  0.75319999,
     &   0.66789997,  0.56879997,  0.46160001,  0.35450000,  0.25370002,
     &   0.16280001,  0.08740002,  0.03479999,  0.00809997,  0.00059998,
     &   0.00000000,  0.00000000,  0.00000000,  0.00000000,  0.00000000,
     &   0.00000000/
      data ((h12(ip,iw),iw=1,31), ip=26,26)/
     &  -0.1513E-06, -0.3009E-06, -0.5966E-06, -0.1176E-05, -0.2299E-05,
     &  -0.4430E-05, -0.8352E-05, -0.1526E-04, -0.2674E-04, -0.4454E-04,
     &  -0.7042E-04, -0.1062E-03, -0.1540E-03, -0.2163E-03, -0.2951E-03,
     &  -0.3899E-03, -0.4948E-03, -0.5983E-03, -0.6846E-03, -0.7332E-03,
     &  -0.7182E-03, -0.6142E-03, -0.4209E-03, -0.2014E-03, -0.5530E-04,
     &  -0.6418E-05, -0.1439E-06,  0.0000E+00,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h13(ip,iw),iw=1,31), ip=26,26)/
     &   0.6817E-09,  0.1359E-08,  0.2702E-08,  0.5374E-08,  0.1061E-07,
     &   0.2079E-07,  0.4022E-07,  0.7610E-07,  0.1392E-06,  0.2428E-06,
     &   0.3992E-06,  0.6149E-06,  0.8893E-06,  0.1220E-05,  0.1599E-05,
     &   0.2015E-05,  0.2453E-05,  0.2853E-05,  0.3173E-05,  0.3488E-05,
     &   0.3792E-05,  0.3800E-05,  0.3210E-05,  0.2002E-05,  0.7234E-06,
     &   0.1068E-06,  0.2646E-08,  0.0000E+00,  0.0000E+00,  0.0000E+00,
     &   0.0000E+00/
      data ((h21(ip,iw),iw=1,31), ip= 1, 1)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997294,  0.99995142,
     &   0.99991685,  0.99986511,  0.99979371,  0.99970162,  0.99958909,
     &   0.99945778,  0.99931037,  0.99914628,  0.99895900,  0.99873799,
     &   0.99846601,  0.99813002,  0.99771398,  0.99719697,  0.99655598,
     &   0.99575800,  0.99475598,  0.99348903,  0.99186200,  0.98973000,
     &   0.98688000,  0.98303002,  0.97777998,  0.97059000,  0.96077001,
     &   0.94742000/
      data ((h22(ip,iw),iw=1,31), ip= 1, 1)/
     &  -0.5622E-07, -0.1071E-06, -0.1983E-06, -0.3533E-06, -0.5991E-06,
     &  -0.9592E-06, -0.1444E-05, -0.2049E-05, -0.2764E-05, -0.3577E-05,
     &  -0.4469E-05, -0.5467E-05, -0.6654E-05, -0.8137E-05, -0.1002E-04,
     &  -0.1237E-04, -0.1528E-04, -0.1884E-04, -0.2310E-04, -0.2809E-04,
     &  -0.3396E-04, -0.4098E-04, -0.4960E-04, -0.6058E-04, -0.7506E-04,
     &  -0.9451E-04, -0.1207E-03, -0.1558E-03, -0.2026E-03, -0.2648E-03,
     &  -0.3468E-03/
      data ((h23(ip,iw),iw=1,31), ip= 1, 1)/
     &  -0.2195E-09, -0.4031E-09, -0.7043E-09, -0.1153E-08, -0.1737E-08,
     &  -0.2395E-08, -0.3020E-08, -0.3549E-08, -0.4034E-08, -0.4421E-08,
     &  -0.4736E-08, -0.5681E-08, -0.8289E-08, -0.1287E-07, -0.1873E-07,
     &  -0.2523E-07, -0.3223E-07, -0.3902E-07, -0.4409E-07, -0.4699E-07,
     &  -0.4782E-07, -0.4705E-07, -0.4657E-07, -0.4885E-07, -0.5550E-07,
     &  -0.6619E-07, -0.7656E-07, -0.8027E-07, -0.7261E-07, -0.4983E-07,
     &  -0.1101E-07/
      data ((h21(ip,iw),iw=1,31), ip= 2, 2)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997294,  0.99995142,
     &   0.99991679,  0.99986511,  0.99979353,  0.99970138,  0.99958861,
     &   0.99945688,  0.99930882,  0.99914342,  0.99895400,  0.99872798,
     &   0.99844801,  0.99809802,  0.99765801,  0.99710101,  0.99639499,
     &   0.99549901,  0.99435198,  0.99287099,  0.99093699,  0.98837000,
     &   0.98491001,  0.98019999,  0.97373998,  0.96490002,  0.95283002,
     &   0.93649000/
      data ((h22(ip,iw),iw=1,31), ip= 2, 2)/
     &  -0.5622E-07, -0.1071E-06, -0.1983E-06, -0.3534E-06, -0.5992E-06,
     &  -0.9594E-06, -0.1445E-05, -0.2050E-05, -0.2766E-05, -0.3580E-05,
     &  -0.4476E-05, -0.5479E-05, -0.6677E-05, -0.8179E-05, -0.1009E-04,
     &  -0.1251E-04, -0.1553E-04, -0.1928E-04, -0.2384E-04, -0.2930E-04,
     &  -0.3588E-04, -0.4393E-04, -0.5403E-04, -0.6714E-04, -0.8458E-04,
     &  -0.1082E-03, -0.1400E-03, -0.1829E-03, -0.2401E-03, -0.3157E-03,
     &  -0.4147E-03/
      data ((h23(ip,iw),iw=1,31), ip= 2, 2)/
     &  -0.2195E-09, -0.4032E-09, -0.7046E-09, -0.1153E-08, -0.1738E-08,
     &  -0.2395E-08, -0.3021E-08, -0.3550E-08, -0.4035E-08, -0.4423E-08,
     &  -0.4740E-08, -0.5692E-08, -0.8314E-08, -0.1292E-07, -0.1882E-07,
     &  -0.2536E-07, -0.3242E-07, -0.3927E-07, -0.4449E-07, -0.4767E-07,
     &  -0.4889E-07, -0.4857E-07, -0.4860E-07, -0.5132E-07, -0.5847E-07,
     &  -0.6968E-07, -0.8037E-07, -0.8400E-07, -0.7521E-07, -0.4830E-07,
     &  -0.7562E-09/
      data ((h21(ip,iw),iw=1,31), ip= 3, 3)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997294,  0.99995142,
     &   0.99991679,  0.99986500,  0.99979341,  0.99970102,  0.99958777,
     &   0.99945557,  0.99930632,  0.99913889,  0.99894601,  0.99871302,
     &   0.99842101,  0.99805099,  0.99757600,  0.99696302,  0.99617100,
     &   0.99514598,  0.99381000,  0.99205798,  0.98974001,  0.98662001,
     &   0.98238999,  0.97659999,  0.96866000,  0.95776999,  0.94296998,
     &   0.92306000/
      data ((h22(ip,iw),iw=1,31), ip= 3, 3)/
     &  -0.5622E-07, -0.1071E-06, -0.1983E-06, -0.3535E-06, -0.5994E-06,
     &  -0.9599E-06, -0.1446E-05, -0.2052E-05, -0.2769E-05, -0.3586E-05,
     &  -0.4487E-05, -0.5499E-05, -0.6712E-05, -0.8244E-05, -0.1021E-04,
     &  -0.1272E-04, -0.1591E-04, -0.1992E-04, -0.2489E-04, -0.3097E-04,
     &  -0.3845E-04, -0.4782E-04, -0.5982E-04, -0.7558E-04, -0.9674E-04,
     &  -0.1254E-03, -0.1644E-03, -0.2167E-03, -0.2863E-03, -0.3777E-03,
     &  -0.4959E-03/
      data ((h23(ip,iw),iw=1,31), ip= 3, 3)/
     &  -0.2196E-09, -0.4033E-09, -0.7048E-09, -0.1154E-08, -0.1739E-08,
     &  -0.2396E-08, -0.3022E-08, -0.3551E-08, -0.4036E-08, -0.4425E-08,
     &  -0.4746E-08, -0.5710E-08, -0.8354E-08, -0.1300E-07, -0.1894E-07,
     &  -0.2554E-07, -0.3265E-07, -0.3958E-07, -0.4502E-07, -0.4859E-07,
     &  -0.5030E-07, -0.5053E-07, -0.5104E-07, -0.5427E-07, -0.6204E-07,
     &  -0.7388E-07, -0.8477E-07, -0.8760E-07, -0.7545E-07, -0.4099E-07,
     &   0.2046E-07/
      data ((h21(ip,iw),iw=1,31), ip= 4, 4)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997294,  0.99995142,
     &   0.99991673,  0.99986482,  0.99979299,  0.99970031,  0.99958658,
     &   0.99945343,  0.99930239,  0.99913180,  0.99893302,  0.99869001,
     &   0.99838102,  0.99798000,  0.99745703,  0.99676800,  0.99586397,
     &   0.99467200,  0.99309403,  0.99099600,  0.98817998,  0.98438001,
     &   0.97918999,  0.97206002,  0.96227002,  0.94888997,  0.93080997,
     &   0.90671003/
      data ((h22(ip,iw),iw=1,31), ip= 4, 4)/
     &  -0.5623E-07, -0.1071E-06, -0.1984E-06, -0.3536E-06, -0.5997E-06,
     &  -0.9606E-06, -0.1447E-05, -0.2055E-05, -0.2775E-05, -0.3596E-05,
     &  -0.4504E-05, -0.5529E-05, -0.6768E-05, -0.8345E-05, -0.1039E-04,
     &  -0.1304E-04, -0.1645E-04, -0.2082E-04, -0.2633E-04, -0.3322E-04,
     &  -0.4187E-04, -0.5292E-04, -0.6730E-04, -0.8640E-04, -0.1122E-03,
     &  -0.1472E-03, -0.1948E-03, -0.2585E-03, -0.3428E-03, -0.4523E-03,
     &  -0.5915E-03/
      data ((h23(ip,iw),iw=1,31), ip= 4, 4)/
     &  -0.2196E-09, -0.4034E-09, -0.7050E-09, -0.1154E-08, -0.1740E-08,
     &  -0.2398E-08, -0.3024E-08, -0.3552E-08, -0.4037E-08, -0.4428E-08,
     &  -0.4756E-08, -0.5741E-08, -0.8418E-08, -0.1310E-07, -0.1910E-07,
     &  -0.2575E-07, -0.3293E-07, -0.3998E-07, -0.4572E-07, -0.4980E-07,
     &  -0.5211E-07, -0.5287E-07, -0.5390E-07, -0.5782E-07, -0.6650E-07,
     &  -0.7892E-07, -0.8940E-07, -0.8980E-07, -0.7119E-07, -0.2452E-07,
     &   0.5823E-07/
      data ((h21(ip,iw),iw=1,31), ip= 5, 5)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997294,  0.99995136,
     &   0.99991661,  0.99986458,  0.99979252,  0.99969929,  0.99958479,
     &   0.99945003,  0.99929619,  0.99912071,  0.99891400,  0.99865502,
     &   0.99831998,  0.99787700,  0.99728799,  0.99650002,  0.99544799,
     &   0.99404198,  0.99215603,  0.98961997,  0.98619002,  0.98153001,
     &   0.97513002,  0.96634001,  0.95428002,  0.93791002,  0.91593999,
     &   0.88700002/
      data ((h22(ip,iw),iw=1,31), ip= 5, 5)/
     &  -0.5623E-07, -0.1071E-06, -0.1985E-06, -0.3538E-06, -0.6002E-06,
     &  -0.9618E-06, -0.1450E-05, -0.2059E-05, -0.2783E-05, -0.3611E-05,
     &  -0.4531E-05, -0.5577E-05, -0.6855E-05, -0.8499E-05, -0.1066E-04,
     &  -0.1351E-04, -0.1723E-04, -0.2207E-04, -0.2829E-04, -0.3621E-04,
     &  -0.4636E-04, -0.5954E-04, -0.7690E-04, -0.1002E-03, -0.1317E-03,
     &  -0.1746E-03, -0.2326E-03, -0.3099E-03, -0.4111E-03, -0.5407E-03,
     &  -0.7020E-03/
      data ((h23(ip,iw),iw=1,31), ip= 5, 5)/
     &  -0.2197E-09, -0.4037E-09, -0.7054E-09, -0.1155E-08, -0.1741E-08,
     &  -0.2401E-08, -0.3027E-08, -0.3553E-08, -0.4039E-08, -0.4431E-08,
     &  -0.4775E-08, -0.5784E-08, -0.8506E-08, -0.1326E-07, -0.1931E-07,
     &  -0.2600E-07, -0.3324E-07, -0.4048E-07, -0.4666E-07, -0.5137E-07,
     &  -0.5428E-07, -0.5558E-07, -0.5730E-07, -0.6228E-07, -0.7197E-07,
     &  -0.8455E-07, -0.9347E-07, -0.8867E-07, -0.5945E-07,  0.5512E-08,
     &   0.1209E-06/
      data ((h21(ip,iw),iw=1,31), ip= 6, 6)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997288,  0.99995130,
     &   0.99991649,  0.99986428,  0.99979180,  0.99969780,  0.99958187,
     &   0.99944460,  0.99928659,  0.99910372,  0.99888301,  0.99860299,
     &   0.99822998,  0.99773002,  0.99705303,  0.99613500,  0.99489301,
     &   0.99321300,  0.99093801,  0.98785001,  0.98365998,  0.97790998,
     &   0.97000998,  0.95916998,  0.94437003,  0.92440999,  0.89789999,
     &   0.86360002/
      data ((h22(ip,iw),iw=1,31), ip= 6, 6)/
     &  -0.5624E-07, -0.1072E-06, -0.1986E-06, -0.3541E-06, -0.6010E-06,
     &  -0.9636E-06, -0.1453E-05, -0.2067E-05, -0.2796E-05, -0.3634E-05,
     &  -0.4572E-05, -0.5652E-05, -0.6987E-05, -0.8733E-05, -0.1107E-04,
     &  -0.1418E-04, -0.1832E-04, -0.2378E-04, -0.3092E-04, -0.4017E-04,
     &  -0.5221E-04, -0.6806E-04, -0.8916E-04, -0.1176E-03, -0.1562E-03,
     &  -0.2087E-03, -0.2793E-03, -0.3724E-03, -0.4928E-03, -0.6440E-03,
     &  -0.8270E-03/
      data ((h23(ip,iw),iw=1,31), ip= 6, 6)/
     &  -0.2198E-09, -0.4040E-09, -0.7061E-09, -0.1156E-08, -0.1744E-08,
     &  -0.2405E-08, -0.3032E-08, -0.3556E-08, -0.4040E-08, -0.4444E-08,
     &  -0.4800E-08, -0.5848E-08, -0.8640E-08, -0.1346E-07, -0.1957E-07,
     &  -0.2627E-07, -0.3357E-07, -0.4114E-07, -0.4793E-07, -0.5330E-07,
     &  -0.5676E-07, -0.5873E-07, -0.6152E-07, -0.6783E-07, -0.7834E-07,
     &  -0.9023E-07, -0.9530E-07, -0.8162E-07, -0.3634E-07,  0.5638E-07,
     &   0.2189E-06/
      data ((h21(ip,iw),iw=1,31), ip= 7, 7)/
     &   0.99999607,  0.99999237,  0.99998546,  0.99997288,  0.99995124,
     &   0.99991626,  0.99986368,  0.99979049,  0.99969530,  0.99957728,
     &   0.99943632,  0.99927181,  0.99907762,  0.99883801,  0.99852502,
     &   0.99810201,  0.99752498,  0.99673301,  0.99564600,  0.99416101,
     &   0.99213398,  0.98936999,  0.98559999,  0.98043001,  0.97333997,
     &   0.96359003,  0.95025003,  0.93216002,  0.90798998,  0.87639999,
     &   0.83609998/
      data ((h22(ip,iw),iw=1,31), ip= 7, 7)/
     &  -0.5626E-07, -0.1072E-06, -0.1987E-06, -0.3545E-06, -0.6022E-06,
     &  -0.9665E-06, -0.1460E-05, -0.2078E-05, -0.2817E-05, -0.3671E-05,
     &  -0.4637E-05, -0.5767E-05, -0.7188E-05, -0.9080E-05, -0.1165E-04,
     &  -0.1513E-04, -0.1981E-04, -0.2609E-04, -0.3441E-04, -0.4534E-04,
     &  -0.5978E-04, -0.7897E-04, -0.1047E-03, -0.1396E-03, -0.1870E-03,
     &  -0.2510E-03, -0.3363E-03, -0.4475E-03, -0.5888E-03, -0.7621E-03,
     &  -0.9647E-03/
      data ((h23(ip,iw),iw=1,31), ip= 7, 7)/
     &  -0.2200E-09, -0.4045E-09, -0.7071E-09, -0.1159E-08, -0.1748E-08,
     &  -0.2411E-08, -0.3040E-08, -0.3561E-08, -0.4046E-08, -0.4455E-08,
     &  -0.4839E-08, -0.5941E-08, -0.8815E-08, -0.1371E-07, -0.1983E-07,
     &  -0.2652E-07, -0.3400E-07, -0.4207E-07, -0.4955E-07, -0.5554E-07,
     &  -0.5966E-07, -0.6261E-07, -0.6688E-07, -0.7454E-07, -0.8521E-07,
     &  -0.9470E-07, -0.9275E-07, -0.6525E-07,  0.3686E-08,  0.1371E-06,
     &   0.3623E-06/
      data ((h21(ip,iw),iw=1,31), ip= 8, 8)/
     &   0.99999607,  0.99999237,  0.99998540,  0.99997282,  0.99995112,
     &   0.99991590,  0.99986279,  0.99978858,  0.99969149,  0.99957019,
     &   0.99942350,  0.99924922,  0.99903822,  0.99877101,  0.99841398,
     &   0.99792302,  0.99724299,  0.99630302,  0.99500000,  0.99320602,
     &   0.99074000,  0.98736000,  0.98272002,  0.97635001,  0.96758002,
     &   0.95555997,  0.93919998,  0.91722000,  0.88819999,  0.85089999,
     &   0.80439997/
      data ((h22(ip,iw),iw=1,31), ip= 8, 8)/
     &  -0.5628E-07, -0.1073E-06, -0.1990E-06, -0.3553E-06, -0.6042E-06,
     &  -0.9710E-06, -0.1469E-05, -0.2096E-05, -0.2849E-05, -0.3728E-05,
     &  -0.4738E-05, -0.5942E-05, -0.7490E-05, -0.9586E-05, -0.1247E-04,
     &  -0.1644E-04, -0.2184E-04, -0.2916E-04, -0.3898E-04, -0.5205E-04,
     &  -0.6948E-04, -0.9285E-04, -0.1244E-03, -0.1672E-03, -0.2251E-03,
     &  -0.3028E-03, -0.4051E-03, -0.5365E-03, -0.6998E-03, -0.8940E-03,
     &  -0.1112E-02/
      data ((h23(ip,iw),iw=1,31), ip= 8, 8)/
     &  -0.2204E-09, -0.4052E-09, -0.7088E-09, -0.1162E-08, -0.1755E-08,
     &  -0.2422E-08, -0.3053E-08, -0.3572E-08, -0.4052E-08, -0.4474E-08,
     &  -0.4898E-08, -0.6082E-08, -0.9046E-08, -0.1400E-07, -0.2009E-07,
     &  -0.2683E-07, -0.3463E-07, -0.4334E-07, -0.5153E-07, -0.5811E-07,
     &  -0.6305E-07, -0.6749E-07, -0.7346E-07, -0.8208E-07, -0.9173E-07,
     &  -0.9603E-07, -0.8264E-07, -0.3505E-07,  0.6878E-07,  0.2586E-06,
     &   0.5530E-06/
      data ((h21(ip,iw),iw=1,31), ip= 9, 9)/
     &   0.99999607,  0.99999237,  0.99998540,  0.99997276,  0.99995089,
     &   0.99991536,  0.99986148,  0.99978572,  0.99968570,  0.99955928,
     &   0.99940401,  0.99921501,  0.99897999,  0.99867398,  0.99825603,
     &   0.99767601,  0.99686497,  0.99573302,  0.99415499,  0.99196899,
     &   0.98895001,  0.98479998,  0.97907001,  0.97119999,  0.96038002,
     &   0.94559997,  0.92565000,  0.89910001,  0.86470002,  0.82130003,
     &   0.76830000/
      data ((h22(ip,iw),iw=1,31), ip= 9, 9)/
     &  -0.5630E-07, -0.1074E-06, -0.1994E-06, -0.3564E-06, -0.6072E-06,
     &  -0.9779E-06, -0.1484E-05, -0.2124E-05, -0.2900E-05, -0.3817E-05,
     &  -0.4891E-05, -0.6205E-05, -0.7931E-05, -0.1031E-04, -0.1362E-04,
     &  -0.1821E-04, -0.2454E-04, -0.3320E-04, -0.4493E-04, -0.6068E-04,
     &  -0.8186E-04, -0.1104E-03, -0.1491E-03, -0.2016E-03, -0.2722E-03,
     &  -0.3658E-03, -0.4873E-03, -0.6404E-03, -0.8253E-03, -0.1037E-02,
     &  -0.1267E-02/
      data ((h23(ip,iw),iw=1,31), ip= 9, 9)/
     &  -0.2207E-09, -0.4061E-09, -0.7117E-09, -0.1169E-08, -0.1767E-08,
     &  -0.2439E-08, -0.3074E-08, -0.3588E-08, -0.4062E-08, -0.4510E-08,
     &  -0.4983E-08, -0.6261E-08, -0.9324E-08, -0.1430E-07, -0.2036E-07,
     &  -0.2725E-07, -0.3561E-07, -0.4505E-07, -0.5384E-07, -0.6111E-07,
     &  -0.6731E-07, -0.7355E-07, -0.8112E-07, -0.8978E-07, -0.9616E-07,
     &  -0.9157E-07, -0.6114E-07,  0.1622E-07,  0.1694E-06,  0.4277E-06,
     &   0.7751E-06/
      data ((h21(ip,iw),iw=1,31), ip=10,10)/
     &   0.99999607,  0.99999237,  0.99998540,  0.99997264,  0.99995059,
     &   0.99991453,  0.99985939,  0.99978119,  0.99967682,  0.99954277,
     &   0.99937469,  0.99916458,  0.99889499,  0.99853599,  0.99804002,
     &   0.99734300,  0.99636298,  0.99498600,  0.99305803,  0.99037802,
     &   0.98667002,  0.98154002,  0.97447002,  0.96473998,  0.95141000,
     &   0.93333000,  0.90916002,  0.87750000,  0.83710003,  0.78729999,
     &   0.72790003/
      data ((h22(ip,iw),iw=1,31), ip=10,10)/
     &  -0.5636E-07, -0.1076E-06, -0.2000E-06, -0.3582E-06, -0.6119E-06,
     &  -0.9888E-06, -0.1507E-05, -0.2168E-05, -0.2978E-05, -0.3952E-05,
     &  -0.5122E-05, -0.6592E-05, -0.8565E-05, -0.1132E-04, -0.1518E-04,
     &  -0.2060E-04, -0.2811E-04, -0.3848E-04, -0.5261E-04, -0.7173E-04,
     &  -0.9758E-04, -0.1326E-03, -0.1801E-03, -0.2442E-03, -0.3296E-03,
     &  -0.4415E-03, -0.5840E-03, -0.7591E-03, -0.9636E-03, -0.1189E-02,
     &  -0.1427E-02/
      data ((h23(ip,iw),iw=1,31), ip=10,10)/
     &  -0.2214E-09, -0.4080E-09, -0.7156E-09, -0.1178E-08, -0.1784E-08,
     &  -0.2466E-08, -0.3105E-08, -0.3617E-08, -0.4087E-08, -0.4563E-08,
     &  -0.5110E-08, -0.6492E-08, -0.9643E-08, -0.1461E-07, -0.2069E-07,
     &  -0.2796E-07, -0.3702E-07, -0.4717E-07, -0.5662E-07, -0.6484E-07,
     &  -0.7271E-07, -0.8079E-07, -0.8928E-07, -0.9634E-07, -0.9625E-07,
     &  -0.7776E-07, -0.2242E-07,  0.9745E-07,  0.3152E-06,  0.6388E-06,
     &   0.9992E-06/
      data ((h21(ip,iw),iw=1,31), ip=11,11)/
     &   0.99999607,  0.99999237,  0.99998534,  0.99997252,  0.99995011,
     &   0.99991328,  0.99985629,  0.99977452,  0.99966347,  0.99951839,
     &   0.99933177,  0.99909180,  0.99877602,  0.99834698,  0.99774700,
     &   0.99690098,  0.99570400,  0.99401599,  0.99164802,  0.98834997,
     &   0.98377001,  0.97742999,  0.96868002,  0.95666999,  0.94032001,
     &   0.91833997,  0.88929999,  0.85189998,  0.80530000,  0.74909997,
     &   0.68299997/
      data ((h22(ip,iw),iw=1,31), ip=11,11)/
     &  -0.5645E-07, -0.1079E-06, -0.2009E-06, -0.3610E-06, -0.6190E-06,
     &  -0.1005E-05, -0.1541E-05, -0.2235E-05, -0.3096E-05, -0.4155E-05,
     &  -0.5463E-05, -0.7150E-05, -0.9453E-05, -0.1269E-04, -0.1728E-04,
     &  -0.2375E-04, -0.3279E-04, -0.4531E-04, -0.6246E-04, -0.8579E-04,
     &  -0.1175E-03, -0.1604E-03, -0.2186E-03, -0.2964E-03, -0.3990E-03,
     &  -0.5311E-03, -0.6957E-03, -0.8916E-03, -0.1112E-02, -0.1346E-02,
     &  -0.1590E-02/
      data ((h23(ip,iw),iw=1,31), ip=11,11)/
     &  -0.2225E-09, -0.4104E-09, -0.7217E-09, -0.1192E-08, -0.1811E-08,
     &  -0.2509E-08, -0.3155E-08, -0.3668E-08, -0.4138E-08, -0.4650E-08,
     &  -0.5296E-08, -0.6785E-08, -0.9991E-08, -0.1494E-07, -0.2122E-07,
     &  -0.2911E-07, -0.3895E-07, -0.4979E-07, -0.6002E-07, -0.6964E-07,
     &  -0.7935E-07, -0.8887E-07, -0.9699E-07, -0.9967E-07, -0.8883E-07,
     &  -0.4988E-07,  0.4156E-07,  0.2197E-06,  0.5081E-06,  0.8667E-06,
     &   0.1212E-05/
      data ((h21(ip,iw),iw=1,31), ip=12,12)/
     &   0.99999607,  0.99999237,  0.99998528,  0.99997234,  0.99994951,
     &   0.99991143,  0.99985188,  0.99976480,  0.99964428,  0.99948311,
     &   0.99927050,  0.99899000,  0.99861199,  0.99809098,  0.99735999,
     &   0.99632198,  0.99484903,  0.99276900,  0.98984998,  0.98576999,
     &   0.98009998,  0.97224998,  0.96144003,  0.94667000,  0.92672002,
     &   0.90020001,  0.86570001,  0.82220000,  0.76919997,  0.70640004,
     &   0.63330001/
      data ((h22(ip,iw),iw=1,31), ip=12,12)/
     &  -0.5658E-07, -0.1083E-06, -0.2023E-06, -0.3650E-06, -0.6295E-06,
     &  -0.1030E-05, -0.1593E-05, -0.2334E-05, -0.3273E-05, -0.4455E-05,
     &  -0.5955E-05, -0.7935E-05, -0.1067E-04, -0.1455E-04, -0.2007E-04,
     &  -0.2788E-04, -0.3885E-04, -0.5409E-04, -0.7503E-04, -0.1036E-03,
     &  -0.1425E-03, -0.1951E-03, -0.2660E-03, -0.3598E-03, -0.4817E-03,
     &  -0.6355E-03, -0.8218E-03, -0.1035E-02, -0.1267E-02, -0.1508E-02,
     &  -0.1755E-02/
      data ((h23(ip,iw),iw=1,31), ip=12,12)/
     &  -0.2241E-09, -0.4142E-09, -0.7312E-09, -0.1214E-08, -0.1854E-08,
     &  -0.2578E-08, -0.3250E-08, -0.3765E-08, -0.4238E-08, -0.4809E-08,
     &  -0.5553E-08, -0.7132E-08, -0.1035E-07, -0.1538E-07, -0.2211E-07,
     &  -0.3079E-07, -0.4142E-07, -0.5303E-07, -0.6437E-07, -0.7566E-07,
     &  -0.8703E-07, -0.9700E-07, -0.1025E-06, -0.9718E-07, -0.6973E-07,
     &  -0.5265E-09,  0.1413E-06,  0.3895E-06,  0.7321E-06,  0.1085E-05,
     &   0.1449E-05/
      data ((h21(ip,iw),iw=1,31), ip=13,13)/
     &   0.99999607,  0.99999231,  0.99998522,  0.99997205,  0.99994856,
     &   0.99990892,  0.99984580,  0.99975121,  0.99961728,  0.99943388,
     &   0.99918568,  0.99884999,  0.99839199,  0.99775398,  0.99685299,
     &   0.99557197,  0.99375200,  0.99117702,  0.98755997,  0.98250002,
     &   0.97548002,  0.96575999,  0.95244002,  0.93436003,  0.91018999,
     &   0.87849998,  0.83810002,  0.78820002,  0.72870004,  0.65910000,
     &   0.57850003/
      data ((h22(ip,iw),iw=1,31), ip=13,13)/
     &  -0.5677E-07, -0.1090E-06, -0.2043E-06, -0.3709E-06, -0.6448E-06,
     &  -0.1066E-05, -0.1669E-05, -0.2480E-05, -0.3532E-05, -0.4887E-05,
     &  -0.6650E-05, -0.9017E-05, -0.1232E-04, -0.1701E-04, -0.2372E-04,
     &  -0.3325E-04, -0.4664E-04, -0.6528E-04, -0.9095E-04, -0.1260E-03,
     &  -0.1737E-03, -0.2381E-03, -0.3238E-03, -0.4359E-03, -0.5789E-03,
     &  -0.7549E-03, -0.9607E-03, -0.1188E-02, -0.1427E-02, -0.1674E-02,
     &  -0.1914E-02/
      data ((h23(ip,iw),iw=1,31), ip=13,13)/
     &  -0.2262E-09, -0.4191E-09, -0.7441E-09, -0.1244E-08, -0.1916E-08,
     &  -0.2687E-08, -0.3407E-08, -0.3947E-08, -0.4432E-08, -0.5059E-08,
     &  -0.5896E-08, -0.7538E-08, -0.1079E-07, -0.1606E-07, -0.2346E-07,
     &  -0.3305E-07, -0.4459E-07, -0.5720E-07, -0.6999E-07, -0.8300E-07,
     &  -0.9536E-07, -0.1039E-06, -0.1036E-06, -0.8526E-07, -0.3316E-07,
     &   0.7909E-07,  0.2865E-06,  0.6013E-06,  0.9580E-06,  0.1303E-05,
     &   0.1792E-05/
      data ((h21(ip,iw),iw=1,31), ip=14,14)/
     &   0.99999607,  0.99999231,  0.99998510,  0.99997163,  0.99994737,
     &   0.99990571,  0.99983770,  0.99973333,  0.99958128,  0.99936771,
     &   0.99907219,  0.99866599,  0.99810302,  0.99731499,  0.99620003,
     &   0.99461198,  0.99235398,  0.98916000,  0.98466998,  0.97839999,
     &   0.96969002,  0.95769000,  0.94133997,  0.91935998,  0.89029998,
     &   0.85290003,  0.80620003,  0.74989998,  0.68369997,  0.60679996,
     &   0.51899999/
      data ((h22(ip,iw),iw=1,31), ip=14,14)/
     &  -0.5703E-07, -0.1098E-06, -0.2071E-06, -0.3788E-06, -0.6657E-06,
     &  -0.1116E-05, -0.1776E-05, -0.2687E-05, -0.3898E-05, -0.5493E-05,
     &  -0.7607E-05, -0.1048E-04, -0.1450E-04, -0.2024E-04, -0.2845E-04,
     &  -0.4014E-04, -0.5658E-04, -0.7947E-04, -0.1110E-03, -0.1541E-03,
     &  -0.2125E-03, -0.2907E-03, -0.3936E-03, -0.5261E-03, -0.6912E-03,
     &  -0.8880E-03, -0.1109E-02, -0.1346E-02, -0.1591E-02, -0.1837E-02,
     &  -0.2054E-02/
      data ((h23(ip,iw),iw=1,31), ip=14,14)/
     &  -0.2288E-09, -0.4265E-09, -0.7627E-09, -0.1289E-08, -0.2011E-08,
     &  -0.2861E-08, -0.3673E-08, -0.4288E-08, -0.4812E-08, -0.5475E-08,
     &  -0.6365E-08, -0.8052E-08, -0.1142E-07, -0.1711E-07, -0.2533E-07,
     &  -0.3597E-07, -0.4862E-07, -0.6259E-07, -0.7708E-07, -0.9150E-07,
     &  -0.1035E-06, -0.1079E-06, -0.9742E-07, -0.5928E-07,  0.2892E-07,
     &   0.1998E-06,  0.4789E-06,  0.8298E-06,  0.1172E-05,  0.1583E-05,
     &   0.2329E-05/
      data ((h21(ip,iw),iw=1,31), ip=15,15)/
     &   0.99999607,  0.99999225,  0.99998498,  0.99997115,  0.99994600,
     &   0.99990171,  0.99982780,  0.99971092,  0.99953562,  0.99928278,
     &   0.99892598,  0.99842799,  0.99773300,  0.99675500,  0.99536800,
     &   0.99339402,  0.99058902,  0.98662001,  0.98104000,  0.97325999,
     &   0.96249002,  0.94773000,  0.92778003,  0.90125000,  0.86680001,
     &   0.82319999,  0.77010000,  0.70730001,  0.63400000,  0.54960001,
     &   0.45560002/
      data ((h22(ip,iw),iw=1,31), ip=15,15)/
     &  -0.5736E-07, -0.1109E-06, -0.2106E-06, -0.3890E-06, -0.6928E-06,
     &  -0.1181E-05, -0.1917E-05, -0.2965E-05, -0.4396E-05, -0.6315E-05,
     &  -0.8891E-05, -0.1242E-04, -0.1736E-04, -0.2442E-04, -0.3454E-04,
     &  -0.4892E-04, -0.6916E-04, -0.9735E-04, -0.1362E-03, -0.1891E-03,
     &  -0.2602E-03, -0.3545E-03, -0.4768E-03, -0.6310E-03, -0.8179E-03,
     &  -0.1032E-02, -0.1265E-02, -0.1508E-02, -0.1757E-02, -0.1989E-02,
     &  -0.2159E-02/
      data ((h23(ip,iw),iw=1,31), ip=15,15)/
     &  -0.2321E-09, -0.4350E-09, -0.7861E-09, -0.1347E-08, -0.2144E-08,
     &  -0.3120E-08, -0.4107E-08, -0.4892E-08, -0.5511E-08, -0.6164E-08,
     &  -0.7054E-08, -0.8811E-08, -0.1240E-07, -0.1862E-07, -0.2773E-07,
     &  -0.3957E-07, -0.5371E-07, -0.6939E-07, -0.8564E-07, -0.1006E-06,
     &  -0.1100E-06, -0.1066E-06, -0.8018E-07, -0.1228E-07,  0.1263E-06,
     &   0.3678E-06,  0.7022E-06,  0.1049E-05,  0.1411E-05,  0.2015E-05,
     &   0.3099E-05/
      data ((h21(ip,iw),iw=1,31), ip=16,16)/
     &   0.99999791,  0.99999589,  0.99999183,  0.99998391,  0.99996853,
     &   0.99993920,  0.99988472,  0.99978709,  0.99961978,  0.99934620,
     &   0.99892199,  0.99830103,  0.99742401,  0.99619502,  0.99445999,
     &   0.99199599,  0.98851001,  0.98360002,  0.97671002,  0.96710002,
     &   0.95378000,  0.93559003,  0.91112000,  0.87900001,  0.83780003,
     &   0.78680003,  0.72549999,  0.65300000,  0.56830001,  0.47140002,
     &   0.36650002/
      data ((h22(ip,iw),iw=1,31), ip=16,16)/
     &  -0.3122E-07, -0.6175E-07, -0.1214E-06, -0.2361E-06, -0.4518E-06,
     &  -0.8438E-06, -0.1524E-05, -0.2643E-05, -0.4380E-05, -0.6922E-05,
     &  -0.1042E-04, -0.1504E-04, -0.2125E-04, -0.2987E-04, -0.4200E-04,
     &  -0.5923E-04, -0.8383E-04, -0.1186E-03, -0.1670E-03, -0.2328E-03,
     &  -0.3204E-03, -0.4347E-03, -0.5802E-03, -0.7595E-03, -0.9703E-03,
     &  -0.1205E-02, -0.1457E-02, -0.1720E-02, -0.1980E-02, -0.2191E-02,
     &  -0.2290E-02/
      data ((h23(ip,iw),iw=1,31), ip=16,16)/
     &  -0.1376E-09, -0.2699E-09, -0.5220E-09, -0.9897E-09, -0.1819E-08,
     &  -0.3186E-08, -0.5224E-08, -0.7896E-08, -0.1090E-07, -0.1349E-07,
     &  -0.1443E-07, -0.1374E-07, -0.1386E-07, -0.1673E-07, -0.2237E-07,
     &  -0.3248E-07, -0.5050E-07, -0.7743E-07, -0.1097E-06, -0.1369E-06,
     &  -0.1463E-06, -0.1268E-06, -0.6424E-07,  0.5941E-07,  0.2742E-06,
     &   0.5924E-06,  0.9445E-06,  0.1286E-05,  0.1819E-05,  0.2867E-05,
     &   0.4527E-05/
      data ((h21(ip,iw),iw=1,31), ip=17,17)/
     &   0.99999756,  0.99999511,  0.99999028,  0.99998081,  0.99996233,
     &   0.99992681,  0.99986011,  0.99973929,  0.99953061,  0.99918979,
     &   0.99866599,  0.99790198,  0.99681997,  0.99528998,  0.99312103,
     &   0.99004799,  0.98571002,  0.97961998,  0.97105998,  0.95915002,
     &   0.94278002,  0.92061001,  0.89120001,  0.85320002,  0.80550003,
     &   0.74759996,  0.67900002,  0.59829998,  0.50520003,  0.40219998,
     &   0.29600000/
      data ((h22(ip,iw),iw=1,31), ip=17,17)/
     &  -0.3547E-07, -0.7029E-07, -0.1386E-06, -0.2709E-06, -0.5218E-06,
     &  -0.9840E-06, -0.1799E-05, -0.3156E-05, -0.5272E-05, -0.8357E-05,
     &  -0.1260E-04, -0.1827E-04, -0.2598E-04, -0.3667E-04, -0.5169E-04,
     &  -0.7312E-04, -0.1037E-03, -0.1467E-03, -0.2060E-03, -0.2857E-03,
     &  -0.3907E-03, -0.5257E-03, -0.6940E-03, -0.8954E-03, -0.1124E-02,
     &  -0.1371E-02, -0.1632E-02, -0.1897E-02, -0.2131E-02, -0.2275E-02,
     &  -0.2265E-02/
      data ((h23(ip,iw),iw=1,31), ip=17,17)/
     &  -0.1482E-09, -0.2910E-09, -0.5667E-09, -0.1081E-08, -0.2005E-08,
     &  -0.3554E-08, -0.5902E-08, -0.8925E-08, -0.1209E-07, -0.1448E-07,
     &  -0.1536E-07, -0.1565E-07, -0.1763E-07, -0.2088E-07, -0.2564E-07,
     &  -0.3635E-07, -0.5791E-07, -0.8907E-07, -0.1213E-06, -0.1418E-06,
     &  -0.1397E-06, -0.1000E-06, -0.4427E-08,  0.1713E-06,  0.4536E-06,
     &   0.8086E-06,  0.1153E-05,  0.1588E-05,  0.2437E-05,  0.3905E-05,
     &   0.5874E-05/
      data ((h21(ip,iw),iw=1,31), ip=18,18)/
     &   0.99999714,  0.99999428,  0.99998862,  0.99997741,  0.99995553,
     &   0.99991333,  0.99983358,  0.99968803,  0.99943441,  0.99901879,
     &   0.99837899,  0.99744099,  0.99609798,  0.99418801,  0.99147803,
     &   0.98764998,  0.98227000,  0.97469997,  0.96410000,  0.94941998,
     &   0.92940998,  0.90263999,  0.86769998,  0.82330000,  0.76880002,
     &   0.70379996,  0.62720001,  0.53810000,  0.43769997,  0.33149999,
     &   0.22839999/
      data ((h22(ip,iw),iw=1,31), ip=18,18)/
     &  -0.4064E-07, -0.8066E-07, -0.1593E-06, -0.3124E-06, -0.6049E-06,
     &  -0.1148E-05, -0.2118E-05, -0.3751E-05, -0.6314E-05, -0.1006E-04,
     &  -0.1526E-04, -0.2232E-04, -0.3196E-04, -0.4525E-04, -0.6394E-04,
     &  -0.9058E-04, -0.1284E-03, -0.1812E-03, -0.2533E-03, -0.3493E-03,
     &  -0.4740E-03, -0.6315E-03, -0.8228E-03, -0.1044E-02, -0.1286E-02,
     &  -0.1544E-02, -0.1810E-02, -0.2061E-02, -0.2243E-02, -0.2291E-02,
     &  -0.2152E-02/
      data ((h23(ip,iw),iw=1,31), ip=18,18)/
     &  -0.1630E-09, -0.3213E-09, -0.6266E-09, -0.1201E-08, -0.2248E-08,
     &  -0.4030E-08, -0.6770E-08, -0.1033E-07, -0.1392E-07, -0.1640E-07,
     &  -0.1768E-07, -0.1932E-07, -0.2229E-07, -0.2508E-07, -0.2940E-07,
     &  -0.4200E-07, -0.6717E-07, -0.1002E-06, -0.1286E-06, -0.1402E-06,
     &  -0.1216E-06, -0.5487E-07,  0.8418E-07,  0.3246E-06,  0.6610E-06,
     &   0.1013E-05,  0.1394E-05,  0.2073E-05,  0.3337E-05,  0.5175E-05,
     &   0.7255E-05/
      data ((h21(ip,iw),iw=1,31), ip=19,19)/
     &   0.99999672,  0.99999344,  0.99998701,  0.99997419,  0.99994916,
     &   0.99990064,  0.99980861,  0.99963921,  0.99934143,  0.99884701,
     &   0.99807602,  0.99692601,  0.99525797,  0.99287403,  0.98948997,
     &   0.98474002,  0.97804999,  0.96867001,  0.95559001,  0.93761998,
     &   0.91336000,  0.88139999,  0.84029996,  0.78920001,  0.72770000,
     &   0.65499997,  0.56999999,  0.47280002,  0.36760002,  0.26220000,
     &   0.16700000/
      data ((h22(ip,iw),iw=1,31), ip=19,19)/
     &  -0.4629E-07, -0.9195E-07, -0.1819E-06, -0.3572E-06, -0.6936E-06,
     &  -0.1323E-05, -0.2456E-05, -0.4385E-05, -0.7453E-05, -0.1200E-04,
     &  -0.1843E-04, -0.2731E-04, -0.3943E-04, -0.5606E-04, -0.7936E-04,
     &  -0.1123E-03, -0.1588E-03, -0.2231E-03, -0.3101E-03, -0.4247E-03,
     &  -0.5713E-03, -0.7522E-03, -0.9651E-03, -0.1202E-02, -0.1456E-02,
     &  -0.1721E-02, -0.1983E-02, -0.2196E-02, -0.2296E-02, -0.2224E-02,
     &  -0.1952E-02/
      data ((h23(ip,iw),iw=1,31), ip=19,19)/
     &  -0.1827E-09, -0.3607E-09, -0.7057E-09, -0.1359E-08, -0.2552E-08,
     &  -0.4615E-08, -0.7854E-08, -0.1218E-07, -0.1670E-07, -0.2008E-07,
     &  -0.2241E-07, -0.2516E-07, -0.2796E-07, -0.3015E-07, -0.3506E-07,
     &  -0.4958E-07, -0.7627E-07, -0.1070E-06, -0.1289E-06, -0.1286E-06,
     &  -0.8843E-07,  0.1492E-07,  0.2118E-06,  0.5155E-06,  0.8665E-06,
     &   0.1220E-05,  0.1765E-05,  0.2825E-05,  0.4498E-05,  0.6563E-05,
     &   0.8422E-05/
      data ((h21(ip,iw),iw=1,31), ip=20,20)/
     &   0.99999636,  0.99999279,  0.99998569,  0.99997163,  0.99994397,
     &   0.99989033,  0.99978799,  0.99959832,  0.99926043,  0.99868900,
     &   0.99777400,  0.99637598,  0.99431503,  0.99134803,  0.98714000,
     &   0.98122001,  0.97290999,  0.96131998,  0.94528997,  0.92346001,
     &   0.89429998,  0.85650003,  0.80879998,  0.75080001,  0.68190002,
     &   0.60100001,  0.50740004,  0.40399998,  0.29729998,  0.19730002,
     &   0.11479998/
      data ((h22(ip,iw),iw=1,31), ip=20,20)/
     &  -0.5164E-07, -0.1026E-06, -0.2031E-06, -0.3994E-06, -0.7771E-06,
     &  -0.1488E-05, -0.2776E-05, -0.5001E-05, -0.8610E-05, -0.1411E-04,
     &  -0.2209E-04, -0.3328E-04, -0.4860E-04, -0.6954E-04, -0.9861E-04,
     &  -0.1393E-03, -0.1961E-03, -0.2738E-03, -0.3778E-03, -0.5132E-03,
     &  -0.6831E-03, -0.8868E-03, -0.1118E-02, -0.1368E-02, -0.1632E-02,
     &  -0.1899E-02, -0.2136E-02, -0.2282E-02, -0.2273E-02, -0.2067E-02,
     &  -0.1679E-02/
      data ((h23(ip,iw),iw=1,31), ip=20,20)/
     &  -0.2058E-09, -0.4066E-09, -0.7967E-09, -0.1539E-08, -0.2904E-08,
     &  -0.5293E-08, -0.9116E-08, -0.1447E-07, -0.2058E-07, -0.2608E-07,
     &  -0.3053E-07, -0.3418E-07, -0.3619E-07, -0.3766E-07, -0.4313E-07,
     &  -0.5817E-07, -0.8299E-07, -0.1072E-06, -0.1195E-06, -0.1031E-06,
     &  -0.3275E-07,  0.1215E-06,  0.3835E-06,  0.7220E-06,  0.1062E-05,
     &   0.1504E-05,  0.2367E-05,  0.3854E-05,  0.5842E-05,  0.7875E-05,
     &   0.9082E-05/
      data ((h21(ip,iw),iw=1,31), ip=21,21)/
     &   0.99999619,  0.99999237,  0.99998480,  0.99996990,  0.99994045,
     &   0.99988312,  0.99977320,  0.99956751,  0.99919540,  0.99855101,
     &   0.99748802,  0.99581498,  0.99329299,  0.98961997,  0.98439002,
     &   0.97702003,  0.96671999,  0.95245999,  0.93291998,  0.90660000,
     &   0.87199998,  0.82780004,  0.77329999,  0.70819998,  0.63119996,
     &   0.54159999,  0.44059998,  0.33380002,  0.23000002,  0.14029998,
     &   0.07340002/
      data ((h22(ip,iw),iw=1,31), ip=21,21)/
     &  -0.5584E-07, -0.1110E-06, -0.2198E-06, -0.4329E-06, -0.8444E-06,
     &  -0.1623E-05, -0.3049E-05, -0.5551E-05, -0.9714E-05, -0.1627E-04,
     &  -0.2609E-04, -0.4015E-04, -0.5955E-04, -0.8603E-04, -0.1223E-03,
     &  -0.1724E-03, -0.2413E-03, -0.3346E-03, -0.4578E-03, -0.6155E-03,
     &  -0.8087E-03, -0.1033E-02, -0.1279E-02, -0.1540E-02, -0.1811E-02,
     &  -0.2065E-02, -0.2251E-02, -0.2301E-02, -0.2163E-02, -0.1828E-02,
     &  -0.1365E-02/
      data ((h23(ip,iw),iw=1,31), ip=21,21)/
     &  -0.2274E-09, -0.4498E-09, -0.8814E-09, -0.1708E-08, -0.3247E-08,
     &  -0.5972E-08, -0.1045E-07, -0.1707E-07, -0.2545E-07, -0.3440E-07,
     &  -0.4259E-07, -0.4822E-07, -0.5004E-07, -0.5061E-07, -0.5485E-07,
     &  -0.6687E-07, -0.8483E-07, -0.9896E-07, -0.9646E-07, -0.5557E-07,
     &   0.5765E-07,  0.2752E-06,  0.5870E-06,  0.9188E-06,  0.1291E-05,
     &   0.1971E-05,  0.3251E-05,  0.5115E-05,  0.7221E-05,  0.8825E-05,
     &   0.9032E-05/
      data ((h21(ip,iw),iw=1,31), ip=22,22)/
     &   0.99999607,  0.99999213,  0.99998438,  0.99996895,  0.99993849,
     &   0.99987900,  0.99976391,  0.99954629,  0.99914569,  0.99843502,
     &   0.99722600,  0.99526101,  0.99221897,  0.98771000,  0.98123002,
     &   0.97209001,  0.95936000,  0.94187999,  0.91820002,  0.88679999,
     &   0.84609997,  0.79530001,  0.73379999,  0.66090000,  0.57529998,
     &   0.47740000,  0.37129998,  0.26490003,  0.16890001,  0.09340000,
     &   0.04310000/
      data ((h22(ip,iw),iw=1,31), ip=22,22)/
     &  -0.5833E-07, -0.1160E-06, -0.2300E-06, -0.4540E-06, -0.8885E-06,
     &  -0.1718E-05, -0.3256E-05, -0.6010E-05, -0.1072E-04, -0.1838E-04,
     &  -0.3026E-04, -0.4772E-04, -0.7223E-04, -0.1057E-03, -0.1512E-03,
     &  -0.2128E-03, -0.2961E-03, -0.4070E-03, -0.5514E-03, -0.7320E-03,
     &  -0.9467E-03, -0.1187E-02, -0.1446E-02, -0.1717E-02, -0.1985E-02,
     &  -0.2203E-02, -0.2307E-02, -0.2237E-02, -0.1965E-02, -0.1532E-02,
     &  -0.1044E-02/
      data ((h23(ip,iw),iw=1,31), ip=22,22)/
     &  -0.2426E-09, -0.4805E-09, -0.9447E-09, -0.1841E-08, -0.3519E-08,
     &  -0.6565E-08, -0.1172E-07, -0.1979E-07, -0.3095E-07, -0.4443E-07,
     &  -0.5821E-07, -0.6868E-07, -0.7282E-07, -0.7208E-07, -0.7176E-07,
     &  -0.7562E-07, -0.8110E-07, -0.7934E-07, -0.5365E-07,  0.2483E-07,
     &   0.1959E-06,  0.4731E-06,  0.7954E-06,  0.1123E-05,  0.1652E-05,
     &   0.2711E-05,  0.4402E-05,  0.6498E-05,  0.8392E-05,  0.9154E-05,
     &   0.8261E-05/
      data ((h21(ip,iw),iw=1,31), ip=23,23)/
     &   0.99999601,  0.99999207,  0.99998420,  0.99996859,  0.99993771,
     &   0.99987692,  0.99975860,  0.99953198,  0.99910772,  0.99833697,
     &   0.99698901,  0.99473202,  0.99113101,  0.98566002,  0.97770000,
     &   0.96640998,  0.95076001,  0.92943001,  0.90092003,  0.86370003,
     &   0.81659997,  0.75889999,  0.69000000,  0.60870004,  0.51440001,
     &   0.40990001,  0.30190003,  0.20060003,  0.11680001,  0.05760002,
     &   0.02270001/
      data ((h22(ip,iw),iw=1,31), ip=23,23)/
     &  -0.5929E-07, -0.1180E-06, -0.2344E-06, -0.4638E-06, -0.9118E-06,
     &  -0.1775E-05, -0.3401E-05, -0.6375E-05, -0.1160E-04, -0.2039E-04,
     &  -0.3444E-04, -0.5575E-04, -0.8641E-04, -0.1287E-03, -0.1856E-03,
     &  -0.2615E-03, -0.3618E-03, -0.4928E-03, -0.6594E-03, -0.8621E-03,
     &  -0.1095E-02, -0.1349E-02, -0.1618E-02, -0.1894E-02, -0.2140E-02,
     &  -0.2293E-02, -0.2290E-02, -0.2085E-02, -0.1696E-02, -0.1212E-02,
     &  -0.7506E-03/
      data ((h23(ip,iw),iw=1,31), ip=23,23)/
     &  -0.2496E-09, -0.4954E-09, -0.9780E-09, -0.1915E-08, -0.3697E-08,
     &  -0.6991E-08, -0.1279E-07, -0.2231E-07, -0.3653E-07, -0.5541E-07,
     &  -0.7688E-07, -0.9614E-07, -0.1069E-06, -0.1065E-06, -0.9866E-07,
     &  -0.8740E-07, -0.7192E-07, -0.4304E-07,  0.1982E-07,  0.1525E-06,
     &   0.3873E-06,  0.6947E-06,  0.1000E-05,  0.1409E-05,  0.2253E-05,
     &   0.3739E-05,  0.5744E-05,  0.7812E-05,  0.9067E-05,  0.8746E-05,
     &   0.6940E-05/
      data ((h21(ip,iw),iw=1,31), ip=24,24)/
     &   0.99999601,  0.99999207,  0.99998420,  0.99996853,  0.99993742,
     &   0.99987602,  0.99975550,  0.99952233,  0.99907869,  0.99825698,
     &   0.99678302,  0.99424398,  0.99007100,  0.98356003,  0.97387999,
     &   0.96004999,  0.94090003,  0.91503000,  0.88099998,  0.83740002,
     &   0.78350002,  0.71869999,  0.64170003,  0.55149996,  0.44950002,
     &   0.34100002,  0.23540002,  0.14380002,  0.07550001,  0.03240001,
     &   0.01029998/
      data ((h22(ip,iw),iw=1,31), ip=24,24)/
     &  -0.5950E-07, -0.1185E-06, -0.2358E-06, -0.4678E-06, -0.9235E-06,
     &  -0.1810E-05, -0.3503E-05, -0.6664E-05, -0.1236E-04, -0.2223E-04,
     &  -0.3849E-04, -0.6396E-04, -0.1017E-03, -0.1545E-03, -0.2257E-03,
     &  -0.3192E-03, -0.4399E-03, -0.5933E-03, -0.7824E-03, -0.1005E-02,
     &  -0.1251E-02, -0.1516E-02, -0.1794E-02, -0.2060E-02, -0.2257E-02,
     &  -0.2318E-02, -0.2186E-02, -0.1853E-02, -0.1386E-02, -0.9021E-03,
     &  -0.5050E-03/
      data ((h23(ip,iw),iw=1,31), ip=24,24)/
     &  -0.2515E-09, -0.5001E-09, -0.9904E-09, -0.1951E-08, -0.3800E-08,
     &  -0.7288E-08, -0.1362E-07, -0.2452E-07, -0.4184E-07, -0.6663E-07,
     &  -0.9770E-07, -0.1299E-06, -0.1533E-06, -0.1584E-06, -0.1425E-06,
     &  -0.1093E-06, -0.5972E-07,  0.1426E-07,  0.1347E-06,  0.3364E-06,
     &   0.6209E-06,  0.9169E-06,  0.1243E-05,  0.1883E-05,  0.3145E-05,
     &   0.5011E-05,  0.7136E-05,  0.8785E-05,  0.9048E-05,  0.7686E-05,
     &   0.5368E-05/
      data ((h21(ip,iw),iw=1,31), ip=25,25)/
     &   0.99999601,  0.99999207,  0.99998420,  0.99996847,  0.99993724,
     &   0.99987543,  0.99975342,  0.99951530,  0.99905682,  0.99819201,
     &   0.99660802,  0.99381101,  0.98908001,  0.98148000,  0.96991003,
     &   0.95317000,  0.92992002,  0.89880002,  0.85839999,  0.80799997,
     &   0.74689996,  0.67420000,  0.58850002,  0.48979998,  0.38200003,
     &   0.27329999,  0.17479998,  0.09700000,  0.04500002,  0.01620001,
     &   0.00349998/
      data ((h22(ip,iw),iw=1,31), ip=25,25)/
     &  -0.5953E-07, -0.1187E-06, -0.2363E-06, -0.4697E-06, -0.9304E-06,
     &  -0.1833E-05, -0.3578E-05, -0.6889E-05, -0.1299E-04, -0.2384E-04,
     &  -0.4227E-04, -0.7201E-04, -0.1174E-03, -0.1825E-03, -0.2710E-03,
     &  -0.3861E-03, -0.5313E-03, -0.7095E-03, -0.9203E-03, -0.1158E-02,
     &  -0.1417E-02, -0.1691E-02, -0.1968E-02, -0.2200E-02, -0.2320E-02,
     &  -0.2263E-02, -0.1998E-02, -0.1563E-02, -0.1068E-02, -0.6300E-03,
     &  -0.3174E-03/
      data ((h23(ip,iw),iw=1,31), ip=25,25)/
     &  -0.2520E-09, -0.5016E-09, -0.9963E-09, -0.1971E-08, -0.3867E-08,
     &  -0.7500E-08, -0.1427E-07, -0.2634E-07, -0.4656E-07, -0.7753E-07,
     &  -0.1196E-06, -0.1683E-06, -0.2113E-06, -0.2309E-06, -0.2119E-06,
     &  -0.1518E-06, -0.5200E-07,  0.9274E-07,  0.2973E-06,  0.5714E-06,
     &   0.8687E-06,  0.1152E-05,  0.1621E-05,  0.2634E-05,  0.4310E-05,
     &   0.6418E-05,  0.8347E-05,  0.9162E-05,  0.8319E-05,  0.6209E-05,
     &   0.3844E-05/
      data ((h21(ip,iw),iw=1,31), ip=26,26)/
     &   0.99999601,  0.99999207,  0.99998420,  0.99996847,  0.99993718,
     &   0.99987501,  0.99975210,  0.99951041,  0.99904078,  0.99814302,
     &   0.99646801,  0.99344200,  0.98819000,  0.97952002,  0.96597999,
     &   0.94600999,  0.91812003,  0.88099998,  0.83359998,  0.77569997,
     &   0.70669997,  0.62529999,  0.53049999,  0.42449999,  0.31419998,
     &   0.20969999,  0.12269998,  0.06089997,  0.02420002,  0.00660002,
     &   0.00040001/
      data ((h22(ip,iw),iw=1,31), ip=26,26)/
     &  -0.5954E-07, -0.1187E-06, -0.2366E-06, -0.4709E-06, -0.9349E-06,
     &  -0.1849E-05, -0.3632E-05, -0.7058E-05, -0.1350E-04, -0.2521E-04,
     &  -0.4564E-04, -0.7958E-04, -0.1329E-03, -0.2114E-03, -0.3200E-03,
     &  -0.4611E-03, -0.6353E-03, -0.8409E-03, -0.1072E-02, -0.1324E-02,
     &  -0.1592E-02, -0.1871E-02, -0.2127E-02, -0.2297E-02, -0.2312E-02,
     &  -0.2123E-02, -0.1738E-02, -0.1247E-02, -0.7744E-03, -0.4117E-03,
     &  -0.1850E-03/
      data ((h23(ip,iw),iw=1,31), ip=26,26)/
     &  -0.2522E-09, -0.5025E-09, -0.9997E-09, -0.1983E-08, -0.3912E-08,
     &  -0.7650E-08, -0.1474E-07, -0.2777E-07, -0.5055E-07, -0.8745E-07,
     &  -0.1414E-06, -0.2095E-06, -0.2790E-06, -0.3241E-06, -0.3135E-06,
     &  -0.2269E-06, -0.5896E-07,  0.1875E-06,  0.4996E-06,  0.8299E-06,
     &   0.1115E-05,  0.1467E-05,  0.2236E-05,  0.3672E-05,  0.5668E-05,
     &   0.7772E-05,  0.9094E-05,  0.8827E-05,  0.7041E-05,  0.4638E-05,
     &   0.2539E-05/
      data ((h81(ip,iw),iw=1,31), ip= 1, 1)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990171,  0.99981678,
     &   0.99967158,  0.99944150,  0.99910933,  0.99867302,  0.99814397,
     &   0.99753898,  0.99686199,  0.99610198,  0.99523401,  0.99421698,
     &   0.99299300,  0.99147898,  0.98958999,  0.98721999,  0.98430002,
     &   0.98071998,  0.97639000,  0.97115999,  0.96480000,  0.95695001,
     &   0.94713998,  0.93469000,  0.91873002,  0.89810002,  0.87129998,
     &   0.83679998/
      data ((h82(ip,iw),iw=1,31), ip= 1, 1)/
     &  -0.5685E-08, -0.1331E-07, -0.3249E-07, -0.8137E-07, -0.2048E-06,
     &  -0.4973E-06, -0.1118E-05, -0.2246E-05, -0.3982E-05, -0.6290E-05,
     &  -0.9040E-05, -0.1215E-04, -0.1567E-04, -0.1970E-04, -0.2449E-04,
     &  -0.3046E-04, -0.3798E-04, -0.4725E-04, -0.5831E-04, -0.7123E-04,
     &  -0.8605E-04, -0.1028E-03, -0.1212E-03, -0.1413E-03, -0.1635E-03,
     &  -0.1884E-03, -0.2160E-03, -0.2461E-03, -0.2778E-03, -0.3098E-03,
     &  -0.3411E-03/
      data ((h83(ip,iw),iw=1,31), ip= 1, 1)/
     &   0.2169E-10,  0.5237E-10,  0.1296E-09,  0.3204E-09,  0.7665E-09,
     &   0.1691E-08,  0.3222E-08,  0.5110E-08,  0.6779E-08,  0.7681E-08,
     &   0.7378E-08,  0.5836E-08,  0.3191E-08, -0.1491E-08, -0.1022E-07,
     &  -0.2359E-07, -0.3957E-07, -0.5553E-07, -0.6927E-07, -0.7849E-07,
     &  -0.8139E-07, -0.7853E-07, -0.7368E-07, -0.7220E-07, -0.7780E-07,
     &  -0.9091E-07, -0.1038E-06, -0.9929E-07, -0.5422E-07,  0.5379E-07,
     &   0.2350E-06/
      data ((h81(ip,iw),iw=1,31), ip= 2, 2)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990171,  0.99981678,
     &   0.99967158,  0.99944139,  0.99910921,  0.99867302,  0.99814397,
     &   0.99753797,  0.99686003,  0.99609798,  0.99522603,  0.99420297,
     &   0.99296701,  0.99142998,  0.98949999,  0.98706001,  0.98400998,
     &   0.98021001,  0.97552001,  0.96976000,  0.96262002,  0.95367002,
     &   0.94234002,  0.92781997,  0.90903997,  0.88459998,  0.85290003,
     &   0.81200004/
      data ((h82(ip,iw),iw=1,31), ip= 2, 2)/
     &  -0.5684E-08, -0.1331E-07, -0.3248E-07, -0.8133E-07, -0.2047E-06,
     &  -0.4971E-06, -0.1117E-05, -0.2245E-05, -0.3981E-05, -0.6287E-05,
     &  -0.9035E-05, -0.1215E-04, -0.1565E-04, -0.1967E-04, -0.2444E-04,
     &  -0.3036E-04, -0.3780E-04, -0.4694E-04, -0.5779E-04, -0.7042E-04,
     &  -0.8491E-04, -0.1013E-03, -0.1196E-03, -0.1399E-03, -0.1625E-03,
     &  -0.1879E-03, -0.2163E-03, -0.2474E-03, -0.2803E-03, -0.3140E-03,
     &  -0.3478E-03/
      data ((h83(ip,iw),iw=1,31), ip= 2, 2)/
     &   0.2168E-10,  0.5242E-10,  0.1295E-09,  0.3201E-09,  0.7662E-09,
     &   0.1690E-08,  0.3220E-08,  0.5106E-08,  0.6776E-08,  0.7673E-08,
     &   0.7362E-08,  0.5808E-08,  0.3138E-08, -0.1595E-08, -0.1041E-07,
     &  -0.2390E-07, -0.4010E-07, -0.5636E-07, -0.7045E-07, -0.7972E-07,
     &  -0.8178E-07, -0.7677E-07, -0.6876E-07, -0.6381E-07, -0.6583E-07,
     &  -0.7486E-07, -0.8229E-07, -0.7017E-07, -0.1497E-07,  0.1051E-06,
     &   0.2990E-06/
      data ((h81(ip,iw),iw=1,31), ip= 3, 3)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990171,  0.99981678,
     &   0.99967152,  0.99944133,  0.99910891,  0.99867201,  0.99814302,
     &   0.99753499,  0.99685597,  0.99609101,  0.99521297,  0.99418002,
     &   0.99292499,  0.99135399,  0.98935997,  0.98681003,  0.98356998,
     &   0.97947001,  0.97430998,  0.96784997,  0.95972002,  0.94941002,
     &   0.93620002,  0.91912001,  0.89690000,  0.86790001,  0.83020002,
     &   0.78210002/
      data ((h82(ip,iw),iw=1,31), ip= 3, 3)/
     &  -0.5682E-08, -0.1330E-07, -0.3247E-07, -0.8129E-07, -0.2046E-06,
     &  -0.4968E-06, -0.1117E-05, -0.2244E-05, -0.3978E-05, -0.6283E-05,
     &  -0.9027E-05, -0.1213E-04, -0.1563E-04, -0.1963E-04, -0.2436E-04,
     &  -0.3021E-04, -0.3754E-04, -0.4649E-04, -0.5709E-04, -0.6940E-04,
     &  -0.8359E-04, -0.9986E-04, -0.1182E-03, -0.1388E-03, -0.1620E-03,
     &  -0.1882E-03, -0.2175E-03, -0.2498E-03, -0.2843E-03, -0.3203E-03,
     &  -0.3573E-03/
      data ((h83(ip,iw),iw=1,31), ip= 3, 3)/
     &   0.2167E-10,  0.5238E-10,  0.1294E-09,  0.3198E-09,  0.7656E-09,
     &   0.1688E-08,  0.3217E-08,  0.5104E-08,  0.6767E-08,  0.7661E-08,
     &   0.7337E-08,  0.5764E-08,  0.3051E-08, -0.1752E-08, -0.1068E-07,
     &  -0.2436E-07, -0.4081E-07, -0.5740E-07, -0.7165E-07, -0.8046E-07,
     &  -0.8082E-07, -0.7289E-07, -0.6141E-07, -0.5294E-07, -0.5134E-07,
     &  -0.5552E-07, -0.5609E-07, -0.3464E-07,  0.3275E-07,  0.1669E-06,
     &   0.3745E-06/
      data ((h81(ip,iw),iw=1,31), ip= 4, 4)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990171,  0.99981678,
     &   0.99967140,  0.99944109,  0.99910849,  0.99867100,  0.99814099,
     &   0.99753201,  0.99685001,  0.99607998,  0.99519402,  0.99414498,
     &   0.99286002,  0.99123698,  0.98914999,  0.98644000,  0.98293000,
     &   0.97842002,  0.97263998,  0.96529001,  0.95592999,  0.94392002,
     &   0.92839003,  0.90815997,  0.88169998,  0.84720004,  0.80269998,
     &   0.74629998/
      data ((h82(ip,iw),iw=1,31), ip= 4, 4)/
     &  -0.5680E-08, -0.1329E-07, -0.3243E-07, -0.8121E-07, -0.2044E-06,
     &  -0.4963E-06, -0.1115E-05, -0.2242E-05, -0.3974E-05, -0.6276E-05,
     &  -0.9015E-05, -0.1211E-04, -0.1559E-04, -0.1956E-04, -0.2423E-04,
     &  -0.2999E-04, -0.3716E-04, -0.4588E-04, -0.5618E-04, -0.6818E-04,
     &  -0.8218E-04, -0.9847E-04, -0.1171E-03, -0.1382E-03, -0.1621E-03,
     &  -0.1892E-03, -0.2197E-03, -0.2535E-03, -0.2902E-03, -0.3293E-03,
     &  -0.3700E-03/
      data ((h83(ip,iw),iw=1,31), ip= 4, 4)/
     &   0.2166E-10,  0.5229E-10,  0.1294E-09,  0.3193E-09,  0.7644E-09,
     &   0.1686E-08,  0.3213E-08,  0.5092E-08,  0.6753E-08,  0.7640E-08,
     &   0.7302E-08,  0.5696E-08,  0.2917E-08, -0.1984E-08, -0.1108E-07,
     &  -0.2497E-07, -0.4171E-07, -0.5849E-07, -0.7254E-07, -0.8017E-07,
     &  -0.7802E-07, -0.6662E-07, -0.5153E-07, -0.3961E-07, -0.3387E-07,
     &  -0.3219E-07, -0.2426E-07,  0.8700E-08,  0.9027E-07,  0.2400E-06,
     &   0.4623E-06/
      data ((h81(ip,iw),iw=1,31), ip= 5, 5)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990165,  0.99981672,
     &   0.99967128,  0.99944091,  0.99910778,  0.99866998,  0.99813801,
     &   0.99752700,  0.99684101,  0.99606299,  0.99516302,  0.99408901,
     &   0.99276000,  0.99105698,  0.98882997,  0.98588997,  0.98202002,
     &   0.97696000,  0.97039002,  0.96192998,  0.95104003,  0.93691999,
     &   0.91851997,  0.89440000,  0.86290002,  0.82200003,  0.76969999,
     &   0.70420003/
      data ((h82(ip,iw),iw=1,31), ip= 5, 5)/
     &  -0.5675E-08, -0.1328E-07, -0.3239E-07, -0.8110E-07, -0.2040E-06,
     &  -0.4954E-06, -0.1114E-05, -0.2238E-05, -0.3968E-05, -0.6265E-05,
     &  -0.8996E-05, -0.1208E-04, -0.1553E-04, -0.1945E-04, -0.2404E-04,
     &  -0.2966E-04, -0.3663E-04, -0.4508E-04, -0.5508E-04, -0.6686E-04,
     &  -0.8082E-04, -0.9732E-04, -0.1165E-03, -0.1382E-03, -0.1630E-03,
     &  -0.1913E-03, -0.2234E-03, -0.2593E-03, -0.2989E-03, -0.3417E-03,
     &  -0.3857E-03/
      data ((h83(ip,iw),iw=1,31), ip= 5, 5)/
     &   0.2163E-10,  0.5209E-10,  0.1291E-09,  0.3186E-09,  0.7626E-09,
     &   0.1682E-08,  0.3203E-08,  0.5078E-08,  0.6730E-08,  0.7606E-08,
     &   0.7246E-08,  0.5592E-08,  0.2735E-08, -0.2325E-08, -0.1162E-07,
     &  -0.2576E-07, -0.4268E-07, -0.5938E-07, -0.7262E-07, -0.7827E-07,
     &  -0.7297E-07, -0.5786E-07, -0.3930E-07, -0.2373E-07, -0.1295E-07,
     &  -0.3728E-08,  0.1465E-07,  0.6114E-07,  0.1590E-06,  0.3257E-06,
     &   0.5622E-06/
      data ((h81(ip,iw),iw=1,31), ip= 6, 6)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990165,  0.99981672,
     &   0.99967122,  0.99944037,  0.99910682,  0.99866802,  0.99813402,
     &   0.99751902,  0.99682599,  0.99603701,  0.99511498,  0.99400300,
     &   0.99260598,  0.99078500,  0.98835999,  0.98510998,  0.98075998,
     &   0.97499001,  0.96741998,  0.95757002,  0.94476998,  0.92804998,
     &   0.90613002,  0.87739998,  0.83990002,  0.79159999,  0.73049998,
     &   0.65540004/
      data ((h82(ip,iw),iw=1,31), ip= 6, 6)/
     &  -0.5671E-08, -0.1326E-07, -0.3234E-07, -0.8091E-07, -0.2035E-06,
     &  -0.4941E-06, -0.1111E-05, -0.2232E-05, -0.3958E-05, -0.6247E-05,
     &  -0.8966E-05, -0.1202E-04, -0.1544E-04, -0.1929E-04, -0.2377E-04,
     &  -0.2921E-04, -0.3593E-04, -0.4409E-04, -0.5385E-04, -0.6555E-04,
     &  -0.7965E-04, -0.9656E-04, -0.1163E-03, -0.1390E-03, -0.1649E-03,
     &  -0.1947E-03, -0.2288E-03, -0.2675E-03, -0.3109E-03, -0.3575E-03,
     &  -0.4039E-03/
      data ((h83(ip,iw),iw=1,31), ip= 6, 6)/
     &   0.2155E-10,  0.5188E-10,  0.1288E-09,  0.3175E-09,  0.7599E-09,
     &   0.1675E-08,  0.3190E-08,  0.5059E-08,  0.6699E-08,  0.7551E-08,
     &   0.7154E-08,  0.5435E-08,  0.2452E-08, -0.2802E-08, -0.1235E-07,
     &  -0.2668E-07, -0.4353E-07, -0.5962E-07, -0.7134E-07, -0.7435E-07,
     &  -0.6551E-07, -0.4676E-07, -0.2475E-07, -0.4876E-08,  0.1235E-07,
     &   0.3092E-07,  0.6192E-07,  0.1243E-06,  0.2400E-06,  0.4247E-06,
     &   0.6755E-06/
      data ((h81(ip,iw),iw=1,31), ip= 7, 7)/
     &   0.99998659,  0.99997360,  0.99994862,  0.99990165,  0.99981660,
     &   0.99967092,  0.99943972,  0.99910510,  0.99866402,  0.99812698,
     &   0.99750602,  0.99680197,  0.99599499,  0.99504000,  0.99387002,
     &   0.99237198,  0.99038202,  0.98768002,  0.98400998,  0.97903001,
     &   0.97236001,  0.96354002,  0.95196998,  0.93681002,  0.91688001,
     &   0.89069998,  0.85640001,  0.81190002,  0.75520003,  0.68470001,
     &   0.59990001/
      data ((h82(ip,iw),iw=1,31), ip= 7, 7)/
     &  -0.5665E-08, -0.1322E-07, -0.3224E-07, -0.8063E-07, -0.2027E-06,
     &  -0.4921E-06, -0.1106E-05, -0.2223E-05, -0.3942E-05, -0.6220E-05,
     &  -0.8920E-05, -0.1194E-04, -0.1530E-04, -0.1905E-04, -0.2337E-04,
     &  -0.2860E-04, -0.3505E-04, -0.4296E-04, -0.5259E-04, -0.6439E-04,
     &  -0.7884E-04, -0.9635E-04, -0.1170E-03, -0.1407E-03, -0.1681E-03,
     &  -0.1998E-03, -0.2366E-03, -0.2790E-03, -0.3265E-03, -0.3763E-03,
     &  -0.4235E-03/
      data ((h83(ip,iw),iw=1,31), ip= 7, 7)/
     &   0.2157E-10,  0.5178E-10,  0.1283E-09,  0.3162E-09,  0.7558E-09,
     &   0.1665E-08,  0.3169E-08,  0.5027E-08,  0.6645E-08,  0.7472E-08,
     &   0.7017E-08,  0.5212E-08,  0.2059E-08, -0.3443E-08, -0.1321E-07,
     &  -0.2754E-07, -0.4389E-07, -0.5869E-07, -0.6825E-07, -0.6819E-07,
     &  -0.5570E-07, -0.3343E-07, -0.7592E-08,  0.1778E-07,  0.4322E-07,
     &   0.7330E-07,  0.1190E-06,  0.1993E-06,  0.3348E-06,  0.5376E-06,
     &   0.8030E-06/
      data ((h81(ip,iw),iw=1,31), ip= 8, 8)/
     &   0.99998659,  0.99997360,  0.99994856,  0.99990159,  0.99981642,
     &   0.99967051,  0.99943858,  0.99910247,  0.99865901,  0.99811602,
     &   0.99748600,  0.99676597,  0.99592900,  0.99492502,  0.99366802,
     &   0.99202400,  0.98979002,  0.98672003,  0.98249000,  0.97671002,
     &   0.96890998,  0.95854002,  0.94483000,  0.92675000,  0.90289998,
     &   0.87160003,  0.83069998,  0.77829999,  0.71239996,  0.63209999,
     &   0.53839999/
      data ((h82(ip,iw),iw=1,31), ip= 8, 8)/
     &  -0.5652E-08, -0.1318E-07, -0.3210E-07, -0.8018E-07, -0.2014E-06,
     &  -0.4888E-06, -0.1099E-05, -0.2210E-05, -0.3918E-05, -0.6179E-05,
     &  -0.8849E-05, -0.1182E-04, -0.1509E-04, -0.1871E-04, -0.2284E-04,
     &  -0.2782E-04, -0.3403E-04, -0.4177E-04, -0.5145E-04, -0.6354E-04,
     &  -0.7853E-04, -0.9681E-04, -0.1185E-03, -0.1437E-03, -0.1729E-03,
     &  -0.2072E-03, -0.2475E-03, -0.2942E-03, -0.3457E-03, -0.3973E-03,
     &  -0.4434E-03/
      data ((h83(ip,iw),iw=1,31), ip= 8, 8)/
     &   0.2153E-10,  0.5151E-10,  0.1273E-09,  0.3136E-09,  0.7488E-09,
     &   0.1649E-08,  0.3142E-08,  0.4980E-08,  0.6559E-08,  0.7346E-08,
     &   0.6813E-08,  0.4884E-08,  0.1533E-08, -0.4209E-08, -0.1409E-07,
     &  -0.2801E-07, -0.4320E-07, -0.5614E-07, -0.6312E-07, -0.5976E-07,
     &  -0.4369E-07, -0.1775E-07,  0.1280E-07,  0.4534E-07,  0.8106E-07,
     &   0.1246E-06,  0.1874E-06,  0.2873E-06,  0.4433E-06,  0.6651E-06,
     &   0.9477E-06/
      data ((h81(ip,iw),iw=1,31), ip= 9, 9)/
     &   0.99998659,  0.99997360,  0.99994856,  0.99990153,  0.99981618,
     &   0.99966979,  0.99943691,  0.99909842,  0.99865001,  0.99809903,
     &   0.99745399,  0.99670798,  0.99582899,  0.99475002,  0.99336600,
     &   0.99151403,  0.98896003,  0.98540002,  0.98044997,  0.97364998,
     &   0.96445000,  0.95213997,  0.93579000,  0.91412002,  0.88550001,
     &   0.84810001,  0.79970002,  0.73850000,  0.66280001,  0.57309997,
     &   0.47189999/
      data ((h82(ip,iw),iw=1,31), ip= 9, 9)/
     &  -0.5629E-08, -0.1310E-07, -0.3186E-07, -0.7948E-07, -0.1995E-06,
     &  -0.4837E-06, -0.1088E-05, -0.2188E-05, -0.3880E-05, -0.6115E-05,
     &  -0.8743E-05, -0.1165E-04, -0.1480E-04, -0.1824E-04, -0.2216E-04,
     &  -0.2691E-04, -0.3293E-04, -0.4067E-04, -0.5057E-04, -0.6314E-04,
     &  -0.7885E-04, -0.9813E-04, -0.1212E-03, -0.1482E-03, -0.1799E-03,
     &  -0.2175E-03, -0.2622E-03, -0.3135E-03, -0.3678E-03, -0.4193E-03,
     &  -0.4627E-03/
      data ((h83(ip,iw),iw=1,31), ip= 9, 9)/
     &   0.2121E-10,  0.5076E-10,  0.1257E-09,  0.3091E-09,  0.7379E-09,
     &   0.1623E-08,  0.3097E-08,  0.4904E-08,  0.6453E-08,  0.7168E-08,
     &   0.6534E-08,  0.4458E-08,  0.8932E-09, -0.5026E-08, -0.1469E-07,
     &  -0.2765E-07, -0.4103E-07, -0.5169E-07, -0.5585E-07, -0.4913E-07,
     &  -0.2954E-07,  0.6372E-09,  0.3738E-07,  0.7896E-07,  0.1272E-06,
     &   0.1867E-06,  0.2682E-06,  0.3895E-06,  0.5672E-06,  0.8091E-06,
     &   0.1114E-05/
      data ((h81(ip,iw),iw=1,31), ip=10,10)/
     &   0.99998659,  0.99997360,  0.99994850,  0.99990141,  0.99981582,
     &   0.99966878,  0.99943417,  0.99909198,  0.99863601,  0.99807203,
     &   0.99740499,  0.99662101,  0.99567503,  0.99448699,  0.99292302,
     &   0.99078500,  0.98780000,  0.98360002,  0.97773999,  0.96968001,
     &   0.95872998,  0.94401997,  0.92440999,  0.89840001,  0.86409998,
     &   0.81959999,  0.76279998,  0.69190001,  0.60650003,  0.50839996,
     &   0.40249997/
      data ((h82(ip,iw),iw=1,31), ip=10,10)/
     &  -0.5597E-08, -0.1300E-07, -0.3148E-07, -0.7838E-07, -0.1964E-06,
     &  -0.4759E-06, -0.1071E-05, -0.2155E-05, -0.3822E-05, -0.6019E-05,
     &  -0.8586E-05, -0.1139E-04, -0.1439E-04, -0.1764E-04, -0.2134E-04,
     &  -0.2591E-04, -0.3188E-04, -0.3978E-04, -0.5011E-04, -0.6334E-04,
     &  -0.7998E-04, -0.1006E-03, -0.1253E-03, -0.1547E-03, -0.1895E-03,
     &  -0.2315E-03, -0.2811E-03, -0.3363E-03, -0.3917E-03, -0.4413E-03,
     &  -0.4809E-03/
      data ((h83(ip,iw),iw=1,31), ip=10,10)/
     &   0.2109E-10,  0.5017E-10,  0.1235E-09,  0.3021E-09,  0.7217E-09,
     &   0.1585E-08,  0.3028E-08,  0.4796E-08,  0.6285E-08,  0.6910E-08,
     &   0.6178E-08,  0.3945E-08,  0.2436E-09, -0.5632E-08, -0.1464E-07,
     &  -0.2596E-07, -0.3707E-07, -0.4527E-07, -0.4651E-07, -0.3644E-07,
     &  -0.1296E-07,  0.2250E-07,  0.6722E-07,  0.1202E-06,  0.1831E-06,
     &   0.2605E-06,  0.3627E-06,  0.5062E-06,  0.7064E-06,  0.9725E-06,
     &   0.1304E-05/
      data ((h81(ip,iw),iw=1,31), ip=11,11)/
     &   0.99998659,  0.99997354,  0.99994850,  0.99990124,  0.99981529,
     &   0.99966723,  0.99942988,  0.99908209,  0.99861503,  0.99803102,
     &   0.99732900,  0.99648702,  0.99544603,  0.99409997,  0.99228698,
     &   0.98977000,  0.98620999,  0.98120999,  0.97421998,  0.96458000,
     &   0.95146000,  0.93378001,  0.91017002,  0.87889999,  0.83810002,
     &   0.78549999,  0.71930003,  0.63859999,  0.54409999,  0.43970001,
     &   0.33249998/
      data ((h82(ip,iw),iw=1,31), ip=11,11)/
     &  -0.5538E-08, -0.1280E-07, -0.3089E-07, -0.7667E-07, -0.1917E-06,
     &  -0.4642E-06, -0.1045E-05, -0.2106E-05, -0.3736E-05, -0.5878E-05,
     &  -0.8363E-05, -0.1104E-04, -0.1387E-04, -0.1692E-04, -0.2044E-04,
     &  -0.2493E-04, -0.3101E-04, -0.3926E-04, -0.5020E-04, -0.6429E-04,
     &  -0.8213E-04, -0.1044E-03, -0.1314E-03, -0.1637E-03, -0.2027E-03,
     &  -0.2498E-03, -0.3042E-03, -0.3617E-03, -0.4163E-03, -0.4625E-03,
     &  -0.4969E-03/
      data ((h83(ip,iw),iw=1,31), ip=11,11)/
     &   0.2067E-10,  0.4903E-10,  0.1200E-09,  0.2917E-09,  0.6965E-09,
     &   0.1532E-08,  0.2925E-08,  0.4632E-08,  0.6054E-08,  0.6590E-08,
     &   0.5746E-08,  0.3436E-08, -0.2251E-09, -0.5703E-08, -0.1344E-07,
     &  -0.2256E-07, -0.3120E-07, -0.3690E-07, -0.3520E-07, -0.2164E-07,
     &   0.6510E-08,  0.4895E-07,  0.1037E-06,  0.1702E-06,  0.2502E-06,
     &   0.3472E-06,  0.4710E-06,  0.6379E-06,  0.8633E-06,  0.1159E-05,
     &   0.1514E-05/
      data ((h81(ip,iw),iw=1,31), ip=12,12)/
     &   0.99998659,  0.99997354,  0.99994838,  0.99990094,  0.99981439,
     &   0.99966472,  0.99942350,  0.99906689,  0.99858302,  0.99796802,
     &   0.99721497,  0.99628800,  0.99510801,  0.99354398,  0.99139601,
     &   0.98838001,  0.98409998,  0.97807997,  0.96967000,  0.95806998,
     &   0.94226003,  0.92093998,  0.89249998,  0.85510004,  0.80659997,
     &   0.74510002,  0.66909999,  0.57870001,  0.47680002,  0.36919999,
     &   0.26520002/
      data ((h82(ip,iw),iw=1,31), ip=12,12)/
     &  -0.5476E-08, -0.1257E-07, -0.3008E-07, -0.7418E-07, -0.1848E-06,
     &  -0.4468E-06, -0.1006E-05, -0.2032E-05, -0.3611E-05, -0.5679E-05,
     &  -0.8058E-05, -0.1059E-04, -0.1324E-04, -0.1612E-04, -0.1956E-04,
     &  -0.2411E-04, -0.3046E-04, -0.3925E-04, -0.5098E-04, -0.6619E-04,
     &  -0.8562E-04, -0.1100E-03, -0.1399E-03, -0.1761E-03, -0.2202E-03,
     &  -0.2726E-03, -0.3306E-03, -0.3885E-03, -0.4404E-03, -0.4820E-03,
     &  -0.5082E-03/
      data ((h83(ip,iw),iw=1,31), ip=12,12)/
     &   0.2041E-10,  0.4771E-10,  0.1149E-09,  0.2782E-09,  0.6614E-09,
     &   0.1451E-08,  0.2778E-08,  0.4401E-08,  0.5736E-08,  0.6189E-08,
     &   0.5315E-08,  0.3087E-08, -0.2518E-09, -0.4806E-08, -0.1071E-07,
     &  -0.1731E-07, -0.2346E-07, -0.2659E-07, -0.2184E-07, -0.4261E-08,
     &   0.2975E-07,  0.8112E-07,  0.1484E-06,  0.2308E-06,  0.3296E-06,
     &   0.4475E-06,  0.5942E-06,  0.7859E-06,  0.1041E-05,  0.1369E-05,
     &   0.1726E-05/
      data ((h81(ip,iw),iw=1,31), ip=13,13)/
     &   0.99998653,  0.99997348,  0.99994826,  0.99990052,  0.99981320,
     &   0.99966109,  0.99941391,  0.99904412,  0.99853402,  0.99787498,
     &   0.99704498,  0.99599600,  0.99462402,  0.99276501,  0.99017602,
     &   0.98651999,  0.98133999,  0.97403997,  0.96386999,  0.94984001,
     &   0.93071002,  0.90495998,  0.87080002,  0.82620001,  0.76910001,
     &   0.69790000,  0.61199999,  0.51320004,  0.40640002,  0.29970002,
     &   0.20359999/
      data ((h82(ip,iw),iw=1,31), ip=13,13)/
     &  -0.5362E-08, -0.1223E-07, -0.2895E-07, -0.7071E-07, -0.1748E-06,
     &  -0.4219E-06, -0.9516E-06, -0.1928E-05, -0.3436E-05, -0.5409E-05,
     &  -0.7666E-05, -0.1005E-04, -0.1254E-04, -0.1533E-04, -0.1880E-04,
     &  -0.2358E-04, -0.3038E-04, -0.3988E-04, -0.5264E-04, -0.6934E-04,
     &  -0.9083E-04, -0.1179E-03, -0.1515E-03, -0.1927E-03, -0.2424E-03,
     &  -0.2994E-03, -0.3591E-03, -0.4155E-03, -0.4634E-03, -0.4982E-03,
     &  -0.5096E-03/
      data ((h83(ip,iw),iw=1,31), ip=13,13)/
     &   0.1976E-10,  0.4551E-10,  0.1086E-09,  0.2601E-09,  0.6126E-09,
     &   0.1345E-08,  0.2583E-08,  0.4112E-08,  0.5365E-08,  0.5796E-08,
     &   0.5031E-08,  0.3182E-08,  0.5970E-09, -0.2547E-08, -0.6172E-08,
     &  -0.1017E-07, -0.1388E-07, -0.1430E-07, -0.6118E-08,  0.1624E-07,
     &   0.5791E-07,  0.1205E-06,  0.2025E-06,  0.3032E-06,  0.4225E-06,
     &   0.5619E-06,  0.7322E-06,  0.9528E-06,  0.1243E-05,  0.1592E-05,
     &   0.1904E-05/
      data ((h81(ip,iw),iw=1,31), ip=14,14)/
     &   0.99998653,  0.99997348,  0.99994808,  0.99989992,  0.99981129,
     &   0.99965578,  0.99939990,  0.99901080,  0.99846399,  0.99773800,
     &   0.99680001,  0.99558002,  0.99394703,  0.99169999,  0.98853999,
     &   0.98408002,  0.97776002,  0.96888000,  0.95652002,  0.93949002,
     &   0.91631001,  0.88529998,  0.84439999,  0.79159999,  0.72510004,
     &   0.64390004,  0.54890001,  0.44379997,  0.33560002,  0.23449999,
     &   0.15009999/
      data ((h82(ip,iw),iw=1,31), ip=14,14)/
     &  -0.5210E-08, -0.1172E-07, -0.2731E-07, -0.6598E-07, -0.1615E-06,
     &  -0.3880E-06, -0.8769E-06, -0.1787E-05, -0.3204E-05, -0.5066E-05,
     &  -0.7197E-05, -0.9451E-05, -0.1185E-04, -0.1465E-04, -0.1831E-04,
     &  -0.2346E-04, -0.3088E-04, -0.4132E-04, -0.5545E-04, -0.7410E-04,
     &  -0.9820E-04, -0.1288E-03, -0.1670E-03, -0.2140E-03, -0.2692E-03,
     &  -0.3293E-03, -0.3886E-03, -0.4417E-03, -0.4840E-03, -0.5073E-03,
     &  -0.4944E-03/
      data ((h83(ip,iw),iw=1,31), ip=14,14)/
     &   0.1880E-10,  0.4271E-10,  0.9966E-10,  0.2352E-09,  0.5497E-09,
     &   0.1205E-08,  0.2334E-08,  0.3765E-08,  0.4993E-08,  0.5532E-08,
     &   0.5148E-08,  0.4055E-08,  0.2650E-08,  0.1326E-08,  0.2019E-09,
     &  -0.1124E-08, -0.2234E-08,  0.2827E-09,  0.1247E-07,  0.4102E-07,
     &   0.9228E-07,  0.1682E-06,  0.2676E-06,  0.3885E-06,  0.5286E-06,
     &   0.6904E-06,  0.8871E-06,  0.1142E-05,  0.1466E-05,  0.1800E-05,
     &   0.2004E-05/
      data ((h81(ip,iw),iw=1,31), ip=15,15)/
     &   0.99998653,  0.99997336,  0.99994785,  0.99989909,  0.99980879,
     &   0.99964851,  0.99938041,  0.99896401,  0.99836302,  0.99754399,
     &   0.99645603,  0.99500400,  0.99302697,  0.99027801,  0.98640001,
     &   0.98092002,  0.97319001,  0.96234000,  0.94727999,  0.92657000,
     &   0.89850003,  0.86119998,  0.81260002,  0.75080001,  0.67429996,
     &   0.58350003,  0.48089999,  0.37250000,  0.26760000,  0.17650002,
     &   0.10610002/
      data ((h82(ip,iw),iw=1,31), ip=15,15)/
     &  -0.5045E-08, -0.1113E-07, -0.2540E-07, -0.6008E-07, -0.1449E-06,
     &  -0.3457E-06, -0.7826E-06, -0.1609E-05, -0.2920E-05, -0.4665E-05,
     &  -0.6691E-05, -0.8868E-05, -0.1127E-04, -0.1422E-04, -0.1820E-04,
     &  -0.2389E-04, -0.3213E-04, -0.4380E-04, -0.5975E-04, -0.8092E-04,
     &  -0.1083E-03, -0.1433E-03, -0.1873E-03, -0.2402E-03, -0.2997E-03,
     &  -0.3607E-03, -0.4178E-03, -0.4662E-03, -0.4994E-03, -0.5028E-03,
     &  -0.4563E-03/
      data ((h83(ip,iw),iw=1,31), ip=15,15)/
     &   0.1804E-10,  0.3983E-10,  0.9045E-10,  0.2080E-09,  0.4786E-09,
     &   0.1046E-08,  0.2052E-08,  0.3413E-08,  0.4704E-08,  0.5565E-08,
     &   0.5887E-08,  0.5981E-08,  0.6202E-08,  0.6998E-08,  0.8493E-08,
     &   0.1002E-07,  0.1184E-07,  0.1780E-07,  0.3483E-07,  0.7122E-07,
     &   0.1341E-06,  0.2259E-06,  0.3446E-06,  0.4866E-06,  0.6486E-06,
     &   0.8343E-06,  0.1063E-05,  0.1356E-05,  0.1690E-05,  0.1951E-05,
     &   0.2005E-05/
      data ((h81(ip,iw),iw=1,31), ip=16,16)/
     &   0.99998647,  0.99997330,  0.99994755,  0.99989808,  0.99980563,
     &   0.99963909,  0.99935490,  0.99890202,  0.99822801,  0.99728203,
     &   0.99599099,  0.99423301,  0.99181002,  0.98842001,  0.98364002,
     &   0.97689003,  0.96740001,  0.95414001,  0.93575001,  0.91060001,
     &   0.87680000,  0.83219999,  0.77490002,  0.70330000,  0.61689997,
     &   0.51750004,  0.40990001,  0.30239999,  0.20539999,  0.12750000,
     &   0.07150000/
      data ((h82(ip,iw),iw=1,31), ip=16,16)/
     &  -0.4850E-08, -0.1045E-07, -0.2334E-07, -0.5367E-07, -0.1265E-06,
     &  -0.2980E-06, -0.6750E-06, -0.1406E-05, -0.2601E-05, -0.4239E-05,
     &  -0.6201E-05, -0.8389E-05, -0.1091E-04, -0.1413E-04, -0.1859E-04,
     &  -0.2500E-04, -0.3432E-04, -0.4761E-04, -0.6595E-04, -0.9030E-04,
     &  -0.1219E-03, -0.1624E-03, -0.2126E-03, -0.2708E-03, -0.3327E-03,
     &  -0.3926E-03, -0.4458E-03, -0.4871E-03, -0.5045E-03, -0.4777E-03,
     &  -0.3954E-03/
      data ((h83(ip,iw),iw=1,31), ip=16,16)/
     &   0.1717E-10,  0.3723E-10,  0.8093E-10,  0.1817E-09,  0.4100E-09,
     &   0.8932E-09,  0.1791E-08,  0.3126E-08,  0.4634E-08,  0.6095E-08,
     &   0.7497E-08,  0.9170E-08,  0.1136E-07,  0.1453E-07,  0.1892E-07,
     &   0.2369E-07,  0.2909E-07,  0.3922E-07,  0.6232E-07,  0.1083E-06,
     &   0.1847E-06,  0.2943E-06,  0.4336E-06,  0.5970E-06,  0.7815E-06,
     &   0.9959E-06,  0.1263E-05,  0.1583E-05,  0.1880E-05,  0.2009E-05,
     &   0.1914E-05/
      data ((h81(ip,iw),iw=1,31), ip=17,17)/
     &   0.99998647,  0.99997318,  0.99994719,  0.99989688,  0.99980187,
     &   0.99962789,  0.99932390,  0.99882400,  0.99805701,  0.99694502,
     &   0.99538797,  0.99323398,  0.99023998,  0.98604000,  0.98013997,
     &   0.97182000,  0.96016002,  0.94391000,  0.92149997,  0.89100003,
     &   0.85049999,  0.79769999,  0.73089999,  0.64919996,  0.55350000,
     &   0.44760001,  0.33870000,  0.23670000,  0.15149999,  0.08810002,
     &   0.04570001/
      data ((h82(ip,iw),iw=1,31), ip=17,17)/
     &  -0.4673E-08, -0.9862E-08, -0.2135E-07, -0.4753E-07, -0.1087E-06,
     &  -0.2512E-06, -0.5671E-06, -0.1199E-05, -0.2281E-05, -0.3842E-05,
     &  -0.5804E-05, -0.8110E-05, -0.1088E-04, -0.1452E-04, -0.1961E-04,
     &  -0.2696E-04, -0.3768E-04, -0.5311E-04, -0.7444E-04, -0.1028E-03,
     &  -0.1397E-03, -0.1865E-03, -0.2427E-03, -0.3047E-03, -0.3667E-03,
     &  -0.4237E-03, -0.4712E-03, -0.5003E-03, -0.4921E-03, -0.4286E-03,
     &  -0.3188E-03/
      data ((h83(ip,iw),iw=1,31), ip=17,17)/
     &   0.1653E-10,  0.3436E-10,  0.7431E-10,  0.1605E-09,  0.3548E-09,
     &   0.7723E-09,  0.1595E-08,  0.2966E-08,  0.4849E-08,  0.7169E-08,
     &   0.1003E-07,  0.1366E-07,  0.1825E-07,  0.2419E-07,  0.3186E-07,
     &   0.4068E-07,  0.5064E-07,  0.6618E-07,  0.9684E-07,  0.1536E-06,
     &   0.2450E-06,  0.3730E-06,  0.5328E-06,  0.7184E-06,  0.9291E-06,
     &   0.1180E-05,  0.1484E-05,  0.1798E-05,  0.1992E-05,  0.1968E-05,
     &   0.1736E-05/
      data ((h81(ip,iw),iw=1,31), ip=18,18)/
     &   0.99998647,  0.99997312,  0.99994683,  0.99989569,  0.99979800,
     &   0.99961591,  0.99928999,  0.99873698,  0.99785602,  0.99653602,
     &   0.99464101,  0.99198103,  0.98825997,  0.98306000,  0.97574002,
     &   0.96548998,  0.95117003,  0.93129998,  0.90407002,  0.86739999,
     &   0.81910002,  0.75720000,  0.68040001,  0.58880001,  0.48530000,
     &   0.37610000,  0.27029997,  0.17830002,  0.10720003,  0.05790001,
     &   0.02740002/
      data ((h82(ip,iw),iw=1,31), ip=18,18)/
     &  -0.4532E-08, -0.9395E-08, -0.1978E-07, -0.4272E-07, -0.9442E-07,
     &  -0.2124E-06, -0.4747E-06, -0.1017E-05, -0.2003E-05, -0.3524E-05,
     &  -0.5567E-05, -0.8108E-05, -0.1127E-04, -0.1547E-04, -0.2138E-04,
     &  -0.2996E-04, -0.4251E-04, -0.6059E-04, -0.8563E-04, -0.1190E-03,
     &  -0.1623E-03, -0.2156E-03, -0.2767E-03, -0.3403E-03, -0.4006E-03,
     &  -0.4530E-03, -0.4912E-03, -0.4995E-03, -0.4563E-03, -0.3592E-03,
     &  -0.2383E-03/
      data ((h83(ip,iw),iw=1,31), ip=18,18)/
     &   0.1593E-10,  0.3276E-10,  0.6896E-10,  0.1476E-09,  0.3190E-09,
     &   0.6944E-09,  0.1474E-08,  0.2935E-08,  0.5300E-08,  0.8697E-08,
     &   0.1336E-07,  0.1946E-07,  0.2707E-07,  0.3637E-07,  0.4800E-07,
     &   0.6187E-07,  0.7806E-07,  0.1008E-06,  0.1404E-06,  0.2089E-06,
     &   0.3153E-06,  0.4613E-06,  0.6416E-06,  0.8506E-06,  0.1095E-05,
     &   0.1387E-05,  0.1708E-05,  0.1956E-05,  0.2003E-05,  0.1836E-05,
     &   0.1483E-05/
      data ((h81(ip,iw),iw=1,31), ip=19,19)/
     &   0.99998641,  0.99997300,  0.99994648,  0.99989462,  0.99979430,
     &   0.99960452,  0.99925661,  0.99864697,  0.99763900,  0.99607199,
     &   0.99376297,  0.99046898,  0.98584002,  0.97937000,  0.97031999,
     &   0.95766997,  0.94010001,  0.91588002,  0.88300002,  0.83920002,
     &   0.78230000,  0.71060002,  0.62360001,  0.52320004,  0.41450000,
     &   0.30589998,  0.20789999,  0.12900001,  0.07239997,  0.03590000,
     &   0.01539999/
      data ((h82(ip,iw),iw=1,31), ip=19,19)/
     &  -0.4448E-08, -0.9085E-08, -0.1877E-07, -0.3946E-07, -0.8472E-07,
     &  -0.1852E-06, -0.4074E-06, -0.8791E-06, -0.1789E-05, -0.3314E-05,
     &  -0.5521E-05, -0.8425E-05, -0.1215E-04, -0.1711E-04, -0.2407E-04,
     &  -0.3421E-04, -0.4905E-04, -0.7032E-04, -0.9985E-04, -0.1394E-03,
     &  -0.1897E-03, -0.2491E-03, -0.3132E-03, -0.3763E-03, -0.4332E-03,
     &  -0.4786E-03, -0.5005E-03, -0.4775E-03, -0.3970E-03, -0.2794E-03,
     &  -0.1652E-03/
      data ((h83(ip,iw),iw=1,31), ip=19,19)/
     &   0.1566E-10,  0.3219E-10,  0.6635E-10,  0.1400E-09,  0.2999E-09,
     &   0.6513E-09,  0.1406E-08,  0.2953E-08,  0.5789E-08,  0.1037E-07,
     &   0.1709E-07,  0.2623E-07,  0.3777E-07,  0.5159E-07,  0.6823E-07,
     &   0.8864E-07,  0.1134E-06,  0.1461E-06,  0.1960E-06,  0.2761E-06,
     &   0.3962E-06,  0.5583E-06,  0.7580E-06,  0.9957E-06,  0.1282E-05,
     &   0.1607E-05,  0.1898E-05,  0.2020E-05,  0.1919E-05,  0.1623E-05,
     &   0.1171E-05/
      data ((h81(ip,iw),iw=1,31), ip=20,20)/
     &   0.99998641,  0.99997294,  0.99994624,  0.99989372,  0.99979132,
     &   0.99959481,  0.99922693,  0.99856299,  0.99742502,  0.99558598,
     &   0.99278802,  0.98872000,  0.98295999,  0.97491002,  0.96368998,
     &   0.94812000,  0.92662001,  0.89719999,  0.85780001,  0.80599999,
     &   0.73969996,  0.65779996,  0.56130004,  0.45410001,  0.34369999,
     &   0.24030000,  0.15390003,  0.08950001,  0.04640001,  0.02090001,
     &   0.00800002/
      data ((h82(ip,iw),iw=1,31), ip=20,20)/
     &  -0.4403E-08, -0.8896E-08, -0.1818E-07, -0.3751E-07, -0.7880E-07,
     &  -0.1683E-06, -0.3640E-06, -0.7852E-06, -0.1640E-05, -0.3191E-05,
     &  -0.5634E-05, -0.9046E-05, -0.1355E-04, -0.1953E-04, -0.2786E-04,
     &  -0.3995E-04, -0.5752E-04, -0.8256E-04, -0.1174E-03, -0.1638E-03,
     &  -0.2211E-03, -0.2854E-03, -0.3507E-03, -0.4116E-03, -0.4633E-03,
     &  -0.4966E-03, -0.4921E-03, -0.4309E-03, -0.3215E-03, -0.2016E-03,
     &  -0.1061E-03/
      data ((h83(ip,iw),iw=1,31), ip=20,20)/
     &   0.1551E-10,  0.3147E-10,  0.6419E-10,  0.1356E-09,  0.2860E-09,
     &   0.6178E-09,  0.1353E-08,  0.2934E-08,  0.6095E-08,  0.1174E-07,
     &   0.2067E-07,  0.3346E-07,  0.5014E-07,  0.7024E-07,  0.9377E-07,
     &   0.1226E-06,  0.1592E-06,  0.2056E-06,  0.2678E-06,  0.3584E-06,
     &   0.4892E-06,  0.6651E-06,  0.8859E-06,  0.1160E-05,  0.1488E-05,
     &   0.1814E-05,  0.2010E-05,  0.1984E-05,  0.1748E-05,  0.1338E-05,
     &   0.8445E-06/
      data ((h81(ip,iw),iw=1,31), ip=21,21)/
     &   0.99998641,  0.99997288,  0.99994606,  0.99989301,  0.99978900,
     &   0.99958712,  0.99920273,  0.99849200,  0.99723101,  0.99511403,
     &   0.99177098,  0.98677999,  0.97962999,  0.96961999,  0.95573002,
     &   0.93658000,  0.91036999,  0.87500000,  0.82800001,  0.76730001,
     &   0.69110000,  0.59930003,  0.49479997,  0.38370001,  0.27590001,
     &   0.18210000,  0.10949999,  0.05919999,  0.02800000,  0.01130003,
     &   0.00389999/
      data ((h82(ip,iw),iw=1,31), ip=21,21)/
     &  -0.4379E-08, -0.8801E-08, -0.1782E-07, -0.3642E-07, -0.7536E-07,
     &  -0.1581E-06, -0.3366E-06, -0.7227E-06, -0.1532E-05, -0.3106E-05,
     &  -0.5810E-05, -0.9862E-05, -0.1540E-04, -0.2279E-04, -0.3292E-04,
     &  -0.4738E-04, -0.6817E-04, -0.9765E-04, -0.1384E-03, -0.1918E-03,
     &  -0.2551E-03, -0.3226E-03, -0.3876E-03, -0.4452E-03, -0.4883E-03,
     &  -0.5005E-03, -0.4598E-03, -0.3633E-03, -0.2416E-03, -0.1349E-03,
     &  -0.6278E-04/
      data ((h83(ip,iw),iw=1,31), ip=21,21)/
     &   0.1542E-10,  0.3111E-10,  0.6345E-10,  0.1310E-09,  0.2742E-09,
     &   0.5902E-09,  0.1289E-08,  0.2826E-08,  0.6103E-08,  0.1250E-07,
     &   0.2355E-07,  0.4041E-07,  0.6347E-07,  0.9217E-07,  0.1256E-06,
     &   0.1658E-06,  0.2175E-06,  0.2824E-06,  0.3607E-06,  0.4614E-06,
     &   0.6004E-06,  0.7880E-06,  0.1034E-05,  0.1349E-05,  0.1698E-05,
     &   0.1965E-05,  0.2021E-05,  0.1857E-05,  0.1500E-05,  0.1015E-05,
     &   0.5467E-06/
      data ((h81(ip,iw),iw=1,31), ip=22,22)/
     &   0.99998635,  0.99997288,  0.99994594,  0.99989259,  0.99978727,
     &   0.99958128,  0.99918407,  0.99843502,  0.99706697,  0.99468601,
     &   0.99077803,  0.98474997,  0.97593999,  0.96350998,  0.94633001,
     &   0.92282999,  0.89100003,  0.84860003,  0.79330003,  0.72299999,
     &   0.63670003,  0.53600001,  0.42580003,  0.31470001,  0.21410000,
     &   0.13300002,  0.07470000,  0.03710002,  0.01580000,  0.00580001,
     &   0.00169998/
      data ((h82(ip,iw),iw=1,31), ip=22,22)/
     &  -0.4366E-08, -0.8749E-08, -0.1761E-07, -0.3578E-07, -0.7322E-07,
     &  -0.1517E-06, -0.3189E-06, -0.6785E-06, -0.1446E-05, -0.3014E-05,
     &  -0.5933E-05, -0.1069E-04, -0.1755E-04, -0.2683E-04, -0.3936E-04,
     &  -0.5675E-04, -0.8137E-04, -0.1160E-03, -0.1630E-03, -0.2223E-03,
     &  -0.2899E-03, -0.3589E-03, -0.4230E-03, -0.4755E-03, -0.5031E-03,
     &  -0.4834E-03, -0.4036E-03, -0.2849E-03, -0.1687E-03, -0.8356E-04,
     &  -0.3388E-04/
      data ((h83(ip,iw),iw=1,31), ip=22,22)/
     &   0.1536E-10,  0.3086E-10,  0.6248E-10,  0.1288E-09,  0.2664E-09,
     &   0.5637E-09,  0.1222E-08,  0.2680E-08,  0.5899E-08,  0.1262E-07,
     &   0.2527E-07,  0.4621E-07,  0.7678E-07,  0.1165E-06,  0.1640E-06,
     &   0.2199E-06,  0.2904E-06,  0.3783E-06,  0.4787E-06,  0.5925E-06,
     &   0.7377E-06,  0.9389E-06,  0.1216E-05,  0.1560E-05,  0.1879E-05,
     &   0.2025E-05,  0.1940E-05,  0.1650E-05,  0.1194E-05,  0.6981E-06,
     &   0.3103E-06/
      data ((h81(ip,iw),iw=1,31), ip=23,23)/
     &   0.99998635,  0.99997282,  0.99994588,  0.99989229,  0.99978608,
     &   0.99957722,  0.99917048,  0.99839097,  0.99693698,  0.99432403,
     &   0.98987001,  0.98273998,  0.97201002,  0.95668000,  0.93548000,
     &   0.90671998,  0.86830002,  0.81800002,  0.75330001,  0.67299998,
     &   0.57720000,  0.46920002,  0.35659999,  0.25010002,  0.16049999,
     &   0.09350002,  0.04850000,  0.02179998,  0.00840002,  0.00269997,
     &   0.00070000/
      data ((h82(ip,iw),iw=1,31), ip=23,23)/
     &  -0.4359E-08, -0.8720E-08, -0.1749E-07, -0.3527E-07, -0.7175E-07,
     &  -0.1473E-06, -0.3062E-06, -0.6451E-06, -0.1372E-05, -0.2902E-05,
     &  -0.5936E-05, -0.1133E-04, -0.1971E-04, -0.3143E-04, -0.4715E-04,
     &  -0.6833E-04, -0.9759E-04, -0.1379E-03, -0.1907E-03, -0.2542E-03,
     &  -0.3239E-03, -0.3935E-03, -0.4559E-03, -0.4991E-03, -0.5009E-03,
     &  -0.4414E-03, -0.3306E-03, -0.2077E-03, -0.1093E-03, -0.4754E-04,
     &  -0.1642E-04/
      data ((h83(ip,iw),iw=1,31), ip=23,23)/
     &   0.1531E-10,  0.3070E-10,  0.6184E-10,  0.1257E-09,  0.2578E-09,
     &   0.5451E-09,  0.1159E-08,  0.2526E-08,  0.5585E-08,  0.1225E-07,
     &   0.2576E-07,  0.5017E-07,  0.8855E-07,  0.1417E-06,  0.2078E-06,
     &   0.2858E-06,  0.3802E-06,  0.4946E-06,  0.6226E-06,  0.7572E-06,
     &   0.9137E-06,  0.1133E-05,  0.1438E-05,  0.1772E-05,  0.1994E-05,
     &   0.1994E-05,  0.1779E-05,  0.1375E-05,  0.8711E-06,  0.4273E-06,
     &   0.1539E-06/
      data ((h81(ip,iw),iw=1,31), ip=24,24)/
     &   0.99998635,  0.99997282,  0.99994582,  0.99989212,  0.99978542,
     &   0.99957442,  0.99916071,  0.99835902,  0.99683702,  0.99403203,
     &   0.98908001,  0.98084998,  0.96805000,  0.94933999,  0.92330998,
     &   0.88830000,  0.84219998,  0.78270000,  0.70809996,  0.61759996,
     &   0.51330000,  0.40079999,  0.29000002,  0.19239998,  0.11619997,
     &   0.06300002,  0.02980000,  0.01200002,  0.00410002,  0.00120002,
     &   0.00019997/
      data ((h82(ip,iw),iw=1,31), ip=24,24)/
     &  -0.4354E-08, -0.8703E-08, -0.1742E-07, -0.3499E-07, -0.7074E-07,
     &  -0.1441E-06, -0.2971E-06, -0.6195E-06, -0.1309E-05, -0.2780E-05,
     &  -0.5823E-05, -0.1165E-04, -0.2152E-04, -0.3616E-04, -0.5604E-04,
     &  -0.8230E-04, -0.1173E-03, -0.1635E-03, -0.2211E-03, -0.2868E-03,
     &  -0.3567E-03, -0.4260E-03, -0.4844E-03, -0.5097E-03, -0.4750E-03,
     &  -0.3779E-03, -0.2522E-03, -0.1409E-03, -0.6540E-04, -0.2449E-04,
     &  -0.6948E-05/
      data ((h83(ip,iw),iw=1,31), ip=24,24)/
     &   0.1529E-10,  0.3060E-10,  0.6142E-10,  0.1241E-09,  0.2535E-09,
     &   0.5259E-09,  0.1107E-08,  0.2383E-08,  0.5243E-08,  0.1161E-07,
     &   0.2523E-07,  0.5188E-07,  0.9757E-07,  0.1657E-06,  0.2553E-06,
     &   0.3629E-06,  0.4878E-06,  0.6323E-06,  0.7923E-06,  0.9575E-06,
     &   0.1139E-05,  0.1381E-05,  0.1687E-05,  0.1952E-05,  0.2029E-05,
     &   0.1890E-05,  0.1552E-05,  0.1062E-05,  0.5728E-06,  0.2280E-06,
     &   0.6762E-07/
      data ((h81(ip,iw),iw=1,31), ip=25,25)/
     &   0.99998635,  0.99997282,  0.99994582,  0.99989200,  0.99978489,
     &   0.99957252,  0.99915391,  0.99833602,  0.99676299,  0.99380499,
     &   0.98843998,  0.97920001,  0.96427000,  0.94182003,  0.91018999,
     &   0.86769998,  0.81260002,  0.74300003,  0.65770000,  0.55750000,
     &   0.44660002,  0.33310002,  0.22860003,  0.14319998,  0.08090001,
     &   0.04030001,  0.01719999,  0.00620002,  0.00190002,  0.00040001,
     &   0.00000000/
      data ((h82(ip,iw),iw=1,31), ip=25,25)/
     &  -0.4352E-08, -0.8693E-08, -0.1738E-07, -0.3483E-07, -0.7006E-07,
     &  -0.1423E-06, -0.2905E-06, -0.6008E-06, -0.1258E-05, -0.2663E-05,
     &  -0.5638E-05, -0.1165E-04, -0.2270E-04, -0.4044E-04, -0.6554E-04,
     &  -0.9855E-04, -0.1407E-03, -0.1928E-03, -0.2534E-03, -0.3197E-03,
     &  -0.3890E-03, -0.4563E-03, -0.5040E-03, -0.4998E-03, -0.4249E-03,
     &  -0.3025E-03, -0.1794E-03, -0.8860E-04, -0.3575E-04, -0.1122E-04,
     &  -0.2506E-05/
      data ((h83(ip,iw),iw=1,31), ip=25,25)/
     &   0.1527E-10,  0.3053E-10,  0.6115E-10,  0.1230E-09,  0.2492E-09,
     &   0.5149E-09,  0.1068E-08,  0.2268E-08,  0.4932E-08,  0.1089E-07,
     &   0.2408E-07,  0.5156E-07,  0.1028E-06,  0.1859E-06,  0.3028E-06,
     &   0.4476E-06,  0.6124E-06,  0.7932E-06,  0.9879E-06,  0.1194E-05,
     &   0.1417E-05,  0.1673E-05,  0.1929E-05,  0.2064E-05,  0.1997E-05,
     &   0.1725E-05,  0.1267E-05,  0.7464E-06,  0.3312E-06,  0.1066E-06,
     &   0.2718E-07/
      data ((h81(ip,iw),iw=1,31), ip=26,26)/
     &   0.99998635,  0.99997282,  0.99994576,  0.99989188,  0.99978459,
     &   0.99957132,  0.99914938,  0.99831998,  0.99670899,  0.99363601,
     &   0.98794001,  0.97781998,  0.96087998,  0.93456000,  0.89670002,
     &   0.84560001,  0.78020000,  0.69920003,  0.60299999,  0.49400002,
     &   0.37910002,  0.26889998,  0.17460001,  0.10280001,  0.05379999,
     &   0.02429998,  0.00929999,  0.00300002,  0.00080001,  0.00010002,
     &   0.00000000/
      data ((h82(ip,iw),iw=1,31), ip=26,26)/
     &  -0.4351E-08, -0.8688E-08, -0.1736E-07, -0.3473E-07, -0.6966E-07,
     &  -0.1405E-06, -0.2857E-06, -0.5867E-06, -0.1218E-05, -0.2563E-05,
     &  -0.5435E-05, -0.1144E-04, -0.2321E-04, -0.4379E-04, -0.7487E-04,
     &  -0.1163E-03, -0.1670E-03, -0.2250E-03, -0.2876E-03, -0.3535E-03,
     &  -0.4215E-03, -0.4826E-03, -0.5082E-03, -0.4649E-03, -0.3564E-03,
     &  -0.2264E-03, -0.1188E-03, -0.5128E-04, -0.1758E-04, -0.4431E-05,
     &  -0.7275E-06/
      data ((h83(ip,iw),iw=1,31), ip=26,26)/
     &   0.1525E-10,  0.3048E-10,  0.6097E-10,  0.1223E-09,  0.2466E-09,
     &   0.5021E-09,  0.1032E-08,  0.2195E-08,  0.4688E-08,  0.1027E-07,
     &   0.2279E-07,  0.4999E-07,  0.1046E-06,  0.2009E-06,  0.3460E-06,
     &   0.5335E-06,  0.7478E-06,  0.9767E-06,  0.1216E-05,  0.1469E-05,
     &   0.1735E-05,  0.1977E-05,  0.2121E-05,  0.2103E-05,  0.1902E-05,
     &   0.1495E-05,  0.9541E-06,  0.4681E-06,  0.1672E-06,  0.4496E-07,
     &   0.9859E-08/
      data ((c1(ip,iw),iw=1,30), ip= 1, 1)/
     &   0.99985647,  0.99976432,  0.99963892,  0.99948031,  0.99927652,
     &   0.99899602,  0.99860001,  0.99804801,  0.99732202,  0.99640399,
     &   0.99526399,  0.99384302,  0.99204999,  0.98979002,  0.98694998,
     &   0.98334998,  0.97878999,  0.97307003,  0.96592999,  0.95722002,
     &   0.94660002,  0.93366003,  0.91777998,  0.89819998,  0.87419999,
     &   0.84500003,  0.81029999,  0.76989996,  0.72440004,  0.67490000/
      data ((c2(ip,iw),iw=1,30), ip= 1, 1)/
     &  -0.1841E-06, -0.4666E-06, -0.1050E-05, -0.2069E-05, -0.3601E-05,
     &  -0.5805E-05, -0.8863E-05, -0.1291E-04, -0.1806E-04, -0.2460E-04,
     &  -0.3317E-04, -0.4452E-04, -0.5944E-04, -0.7884E-04, -0.1036E-03,
     &  -0.1346E-03, -0.1727E-03, -0.2186E-03, -0.2728E-03, -0.3364E-03,
     &  -0.4102E-03, -0.4948E-03, -0.5890E-03, -0.6900E-03, -0.7930E-03,
     &  -0.8921E-03, -0.9823E-03, -0.1063E-02, -0.1138E-02, -0.1214E-02/
      data ((c3(ip,iw),iw=1,30), ip= 1, 1)/
     &   0.5821E-10,  0.5821E-10, -0.3201E-09, -0.1804E-08, -0.4336E-08,
     &  -0.7829E-08, -0.1278E-07, -0.1847E-07, -0.2827E-07, -0.4495E-07,
     &  -0.7126E-07, -0.1071E-06, -0.1524E-06, -0.2160E-06, -0.3014E-06,
     &  -0.4097E-06, -0.5349E-06, -0.6718E-06, -0.8125E-06, -0.9755E-06,
     &  -0.1157E-05, -0.1339E-05, -0.1492E-05, -0.1563E-05, -0.1485E-05,
     &  -0.1210E-05, -0.7280E-06, -0.1107E-06,  0.5369E-06,  0.1154E-05/
      data ((c1(ip,iw),iw=1,30), ip= 2, 2)/
     &   0.99985647,  0.99976432,  0.99963868,  0.99947977,  0.99927580,
     &   0.99899501,  0.99859601,  0.99804401,  0.99731201,  0.99638498,
     &   0.99523097,  0.99378198,  0.99194402,  0.98961002,  0.98664999,
     &   0.98286998,  0.97807002,  0.97200000,  0.96439999,  0.95503998,
     &   0.94352001,  0.92931998,  0.91175002,  0.88989997,  0.86300004,
     &   0.83039999,  0.79159999,  0.74710000,  0.69790000,  0.64579999/
      data ((c2(ip,iw),iw=1,30), ip= 2, 2)/
     &  -0.1831E-06, -0.4642E-06, -0.1048E-05, -0.2067E-05, -0.3596E-05,
     &  -0.5797E-05, -0.8851E-05, -0.1289E-04, -0.1802E-04, -0.2454E-04,
     &  -0.3307E-04, -0.4435E-04, -0.5916E-04, -0.7842E-04, -0.1031E-03,
     &  -0.1342E-03, -0.1725E-03, -0.2189E-03, -0.2739E-03, -0.3386E-03,
     &  -0.4138E-03, -0.5003E-03, -0.5968E-03, -0.7007E-03, -0.8076E-03,
     &  -0.9113E-03, -0.1007E-02, -0.1096E-02, -0.1181E-02, -0.1271E-02/
      data ((c3(ip,iw),iw=1,30), ip= 2, 2)/
     &   0.5821E-10,  0.5821E-10, -0.3347E-09, -0.1746E-08, -0.4366E-08,
     &  -0.7858E-08, -0.1262E-07, -0.1866E-07, -0.2849E-07, -0.4524E-07,
     &  -0.7176E-07, -0.1077E-06, -0.1531E-06, -0.2166E-06, -0.3018E-06,
     &  -0.4090E-06, -0.5327E-06, -0.6670E-06, -0.8088E-06, -0.9714E-06,
     &  -0.1151E-05, -0.1333E-05, -0.1483E-05, -0.1548E-05, -0.1467E-05,
     &  -0.1192E-05, -0.7159E-06, -0.1032E-06,  0.5571E-06,  0.1217E-05/
      data ((c1(ip,iw),iw=1,30), ip= 3, 3)/
     &   0.99985671,  0.99976432,  0.99963838,  0.99947912,  0.99927449,
     &   0.99899203,  0.99859202,  0.99803501,  0.99729699,  0.99635702,
     &   0.99518001,  0.99369103,  0.99178600,  0.98935002,  0.98623002,
     &   0.98223001,  0.97711003,  0.97060001,  0.96243000,  0.95222998,
     &   0.93957001,  0.92379999,  0.90411001,  0.87959999,  0.84930003,
     &   0.81270003,  0.76980001,  0.72140002,  0.66909999,  0.61539996/
      data ((c2(ip,iw),iw=1,30), ip= 3, 3)/
     &  -0.1831E-06, -0.4623E-06, -0.1048E-05, -0.2065E-05, -0.3589E-05,
     &  -0.5789E-05, -0.8833E-05, -0.1286E-04, -0.1797E-04, -0.2446E-04,
     &  -0.3292E-04, -0.4412E-04, -0.5880E-04, -0.7795E-04, -0.1027E-03,
     &  -0.1340E-03, -0.1728E-03, -0.2199E-03, -0.2759E-03, -0.3419E-03,
     &  -0.4194E-03, -0.5081E-03, -0.6078E-03, -0.7156E-03, -0.8270E-03,
     &  -0.9365E-03, -0.1040E-02, -0.1137E-02, -0.1235E-02, -0.1339E-02/
      data ((c3(ip,iw),iw=1,30), ip= 3, 3)/
     &   0.2910E-10,  0.5821E-10, -0.3201E-09, -0.1732E-08, -0.4307E-08,
     &  -0.7843E-08, -0.1270E-07, -0.1882E-07, -0.2862E-07, -0.4571E-07,
     &  -0.7225E-07, -0.1082E-06, -0.1535E-06, -0.2171E-06, -0.3021E-06,
     &  -0.4084E-06, -0.5302E-06, -0.6615E-06, -0.8059E-06, -0.9668E-06,
     &  -0.1146E-05, -0.1325E-05, -0.1468E-05, -0.1530E-05, -0.1448E-05,
     &  -0.1168E-05, -0.6907E-06, -0.7148E-07,  0.6242E-06,  0.1357E-05/
      data ((c1(ip,iw),iw=1,30), ip= 4, 4)/
     &   0.99985629,  0.99976349,  0.99963838,  0.99947798,  0.99927282,
     &   0.99898797,  0.99858499,  0.99802202,  0.99727303,  0.99631298,
     &   0.99510002,  0.99355298,  0.99155599,  0.98898000,  0.98566002,
     &   0.98136997,  0.97584999,  0.96880001,  0.95986998,  0.94862998,
     &   0.93452001,  0.91681999,  0.89459997,  0.86680001,  0.83270001,
     &   0.79189998,  0.74479997,  0.69290000,  0.63839996,  0.58410001/
      data ((c2(ip,iw),iw=1,30), ip= 4, 4)/
     &  -0.1808E-06, -0.4642E-06, -0.1045E-05, -0.2058E-05, -0.3581E-05,
     &  -0.5776E-05, -0.8801E-05, -0.1281E-04, -0.1789E-04, -0.2433E-04,
     &  -0.3273E-04, -0.4382E-04, -0.5840E-04, -0.7755E-04, -0.1024E-03,
     &  -0.1342E-03, -0.1737E-03, -0.2217E-03, -0.2791E-03, -0.3473E-03,
     &  -0.4272E-03, -0.5191E-03, -0.6227E-03, -0.7354E-03, -0.8526E-03,
     &  -0.9688E-03, -0.1081E-02, -0.1189E-02, -0.1300E-02, -0.1417E-02/
      data ((c3(ip,iw),iw=1,30), ip= 4, 4)/
     &   0.1019E-09,  0.1601E-09, -0.4075E-09, -0.1746E-08, -0.4366E-08,
     &  -0.7960E-08, -0.1294E-07, -0.1898E-07, -0.2899E-07, -0.4594E-07,
     &  -0.7267E-07, -0.1088E-06, -0.1536E-06, -0.2164E-06, -0.3002E-06,
     &  -0.4055E-06, -0.5260E-06, -0.6571E-06, -0.8022E-06, -0.9624E-06,
     &  -0.1139E-05, -0.1315E-05, -0.1456E-05, -0.1512E-05, -0.1420E-05,
     &  -0.1137E-05, -0.6483E-06,  0.6679E-08,  0.7652E-06,  0.1574E-05/
      data ((c1(ip,iw),iw=1,30), ip= 5, 5)/
     &   0.99985641,  0.99976403,  0.99963748,  0.99947661,  0.99926913,
     &   0.99898303,  0.99857402,  0.99800003,  0.99723399,  0.99624503,
     &   0.99498397,  0.99335301,  0.99123502,  0.98847997,  0.98488998,
     &   0.98023999,  0.97421998,  0.96648002,  0.95659000,  0.94404000,
     &   0.92815000,  0.90802002,  0.88270003,  0.85119998,  0.81290001,
     &   0.76770002,  0.71679997,  0.66219997,  0.60670000,  0.55250001/
      data ((c2(ip,iw),iw=1,30), ip= 5, 5)/
     &  -0.1827E-06, -0.4608E-06, -0.1042E-05, -0.2053E-05, -0.3565E-05,
     &  -0.5745E-05, -0.8758E-05, -0.1273E-04, -0.1778E-04, -0.2417E-04,
     &  -0.3250E-04, -0.4347E-04, -0.5801E-04, -0.7729E-04, -0.1025E-03,
     &  -0.1349E-03, -0.1755E-03, -0.2249E-03, -0.2842E-03, -0.3549E-03,
     &  -0.4380E-03, -0.5340E-03, -0.6428E-03, -0.7613E-03, -0.8854E-03,
     &  -0.1009E-02, -0.1131E-02, -0.1252E-02, -0.1376E-02, -0.1502E-02/
      data ((c3(ip,iw),iw=1,30), ip= 5, 5)/
     &   0.4366E-10, -0.1455E-10, -0.4075E-09, -0.1804E-08, -0.4293E-08,
     &  -0.8178E-08, -0.1301E-07, -0.1915E-07, -0.2938E-07, -0.4664E-07,
     &  -0.7365E-07, -0.1090E-06, -0.1539E-06, -0.2158E-06, -0.2992E-06,
     &  -0.4033E-06, -0.5230E-06, -0.6537E-06, -0.7976E-06, -0.9601E-06,
     &  -0.1135E-05, -0.1305E-05, -0.1440E-05, -0.1490E-05, -0.1389E-05,
     &  -0.1087E-05, -0.5646E-06,  0.1475E-06,  0.9852E-06,  0.1853E-05/
      data ((c1(ip,iw),iw=1,30), ip= 6, 6)/
     &   0.99985617,  0.99976331,  0.99963629,  0.99947429,  0.99926388,
     &   0.99897301,  0.99855602,  0.99796802,  0.99717802,  0.99614400,
     &   0.99480897,  0.99306899,  0.99078500,  0.98778999,  0.98387998,
     &   0.97876000,  0.97211999,  0.96350002,  0.95240998,  0.93821001,
     &   0.92009002,  0.89709997,  0.86820000,  0.83249998,  0.78970003,
     &   0.74039996,  0.68630004,  0.63010001,  0.57459998,  0.52069998/
      data ((c2(ip,iw),iw=1,30), ip= 6, 6)/
     &  -0.1798E-06, -0.4580E-06, -0.1033E-05, -0.2039E-05, -0.3544E-05,
     &  -0.5709E-05, -0.8696E-05, -0.1264E-04, -0.1763E-04, -0.2395E-04,
     &  -0.3220E-04, -0.4311E-04, -0.5777E-04, -0.7732E-04, -0.1032E-03,
     &  -0.1365E-03, -0.1784E-03, -0.2295E-03, -0.2914E-03, -0.3653E-03,
     &  -0.4527E-03, -0.5541E-03, -0.6689E-03, -0.7947E-03, -0.9265E-03,
     &  -0.1060E-02, -0.1192E-02, -0.1326E-02, -0.1460E-02, -0.1586E-02/
      data ((c3(ip,iw),iw=1,30), ip= 6, 6)/
     &   0.8731E-10,  0.0000E+00, -0.3492E-09, -0.1892E-08, -0.4322E-08,
     &  -0.8367E-08, -0.1318E-07, -0.1962E-07, -0.3024E-07, -0.4708E-07,
     &  -0.7359E-07, -0.1087E-06, -0.1534E-06, -0.2152E-06, -0.2978E-06,
     &  -0.4008E-06, -0.5207E-06, -0.6509E-06, -0.7968E-06, -0.9584E-06,
     &  -0.1128E-05, -0.1297E-05, -0.1425E-05, -0.1461E-05, -0.1342E-05,
     &  -0.1009E-05, -0.4283E-06,  0.3666E-06,  0.1272E-05,  0.2171E-05/
      data ((c1(ip,iw),iw=1,30), ip= 7, 7)/
     &   0.99985600,  0.99976230,  0.99963462,  0.99947017,  0.99925607,
     &   0.99895698,  0.99852800,  0.99791902,  0.99709100,  0.99599499,
     &   0.99456000,  0.99267203,  0.99017102,  0.98688000,  0.98255002,
     &   0.97685999,  0.96941000,  0.95969999,  0.94709998,  0.93085998,
     &   0.91001999,  0.88360000,  0.85060000,  0.81040001,  0.76319999,
     &   0.71029997,  0.65400004,  0.59740001,  0.54229999,  0.48839998/
      data ((c2(ip,iw),iw=1,30), ip= 7, 7)/
     &  -0.1784E-06, -0.4551E-06, -0.1023E-05, -0.2019E-05, -0.3507E-05,
     &  -0.5651E-05, -0.8608E-05, -0.1250E-04, -0.1744E-04, -0.2370E-04,
     &  -0.3189E-04, -0.4289E-04, -0.5777E-04, -0.7787E-04, -0.1045E-03,
     &  -0.1392E-03, -0.1828E-03, -0.2365E-03, -0.3015E-03, -0.3797E-03,
     &  -0.4723E-03, -0.5803E-03, -0.7026E-03, -0.8365E-03, -0.9772E-03,
     &  -0.1120E-02, -0.1265E-02, -0.1409E-02, -0.1547E-02, -0.1665E-02/
      data ((c3(ip,iw),iw=1,30), ip= 7, 7)/
     &   0.5821E-10,  0.8731E-10, -0.4366E-09, -0.1935E-08, -0.4555E-08,
     &  -0.8455E-08, -0.1356E-07, -0.2024E-07, -0.3079E-07, -0.4758E-07,
     &  -0.7352E-07, -0.1078E-06, -0.1520E-06, -0.2139E-06, -0.2964E-06,
     &  -0.3997E-06, -0.5185E-06, -0.6493E-06, -0.7943E-06, -0.9568E-06,
     &  -0.1127E-05, -0.1288E-05, -0.1405E-05, -0.1425E-05, -0.1275E-05,
     &  -0.8809E-06, -0.2158E-06,  0.6597E-06,  0.1610E-05,  0.2524E-05/
      data ((c1(ip,iw),iw=1,30), ip= 8, 8)/
     &   0.99985582,  0.99976122,  0.99963123,  0.99946368,  0.99924308,
     &   0.99893397,  0.99848598,  0.99784499,  0.99696398,  0.99577999,
     &   0.99421299,  0.99212801,  0.98935997,  0.98569000,  0.98083001,
     &   0.97442001,  0.96595001,  0.95486999,  0.94040000,  0.92163002,
     &   0.89760000,  0.86720002,  0.82969999,  0.78499997,  0.73370004,
     &   0.67799997,  0.62070000,  0.56439996,  0.50960004,  0.45539999/
      data ((c2(ip,iw),iw=1,30), ip= 8, 8)/
     &  -0.1760E-06, -0.4451E-06, -0.1004E-05, -0.1989E-05, -0.3457E-05,
     &  -0.5574E-05, -0.8470E-05, -0.1230E-04, -0.1721E-04, -0.2344E-04,
     &  -0.3168E-04, -0.4286E-04, -0.5815E-04, -0.7898E-04, -0.1070E-03,
     &  -0.1434E-03, -0.1892E-03, -0.2460E-03, -0.3152E-03, -0.3985E-03,
     &  -0.4981E-03, -0.6139E-03, -0.7448E-03, -0.8878E-03, -0.1038E-02,
     &  -0.1193E-02, -0.1348E-02, -0.1499E-02, -0.1631E-02, -0.1735E-02/
      data ((c3(ip,iw),iw=1,30), ip= 8, 8)/
     &  -0.1455E-10,  0.4366E-10, -0.3929E-09, -0.2081E-08, -0.4700E-08,
     &  -0.8804E-08, -0.1417E-07, -0.2068E-07, -0.3143E-07, -0.4777E-07,
     &  -0.7336E-07, -0.1070E-06, -0.1517E-06, -0.2134E-06, -0.2967E-06,
     &  -0.3991E-06, -0.5164E-06, -0.6510E-06, -0.7979E-06, -0.9575E-06,
     &  -0.1123E-05, -0.1279E-05, -0.1382E-05, -0.1374E-05, -0.1166E-05,
     &  -0.6893E-06,  0.7339E-07,  0.1013E-05,  0.1982E-05,  0.2896E-05/
      data ((c1(ip,iw),iw=1,30), ip= 9, 9)/
     &   0.99985498,  0.99975908,  0.99962622,  0.99945402,  0.99922228,
     &   0.99889803,  0.99842203,  0.99773699,  0.99677801,  0.99547797,
     &   0.99373603,  0.99140298,  0.98829001,  0.98413998,  0.97863001,
     &   0.97127002,  0.96156001,  0.94875997,  0.93197000,  0.91017997,
     &   0.88230002,  0.84749997,  0.80540001,  0.75620002,  0.70159996,
     &   0.64429998,  0.58710003,  0.53130001,  0.47640002,  0.42189997/
      data ((c2(ip,iw),iw=1,30), ip= 9, 9)/
     &  -0.1717E-06, -0.4327E-06, -0.9759E-06, -0.1943E-05, -0.3391E-05,
     &  -0.5454E-05, -0.8297E-05, -0.1209E-04, -0.1697E-04, -0.2322E-04,
     &  -0.3163E-04, -0.4318E-04, -0.5910E-04, -0.8111E-04, -0.1108E-03,
     &  -0.1493E-03, -0.1982E-03, -0.2588E-03, -0.3333E-03, -0.4237E-03,
     &  -0.5312E-03, -0.6562E-03, -0.7968E-03, -0.9496E-03, -0.1110E-02,
     &  -0.1276E-02, -0.1439E-02, -0.1588E-02, -0.1708E-02, -0.1796E-02/
      data ((c3(ip,iw),iw=1,30), ip= 9, 9)/
     &   0.0000E+00,  0.1455E-10, -0.3638E-09, -0.2299E-08, -0.4744E-08,
     &  -0.9284E-08, -0.1445E-07, -0.2141E-07, -0.3162E-07, -0.4761E-07,
     &  -0.7248E-07, -0.1065E-06, -0.1501E-06, -0.2140E-06, -0.2981E-06,
     &  -0.3994E-06, -0.5201E-06, -0.6549E-06, -0.8009E-06, -0.9627E-06,
     &  -0.1125E-05, -0.1266E-05, -0.1348E-05, -0.1292E-05, -0.1005E-05,
     &  -0.4166E-06,  0.4279E-06,  0.1401E-05,  0.2379E-05,  0.3278E-05/
      data ((c1(ip,iw),iw=1,30), ip=10,10)/
     &   0.99985462,  0.99975640,  0.99961889,  0.99943668,  0.99919188,
     &   0.99884301,  0.99832898,  0.99757999,  0.99651998,  0.99506402,
     &   0.99309200,  0.99044400,  0.98689002,  0.98215997,  0.97579002,
     &   0.96730000,  0.95603001,  0.94110000,  0.92149001,  0.89609998,
     &   0.86399996,  0.82449996,  0.77759999,  0.72459996,  0.66769999,
     &   0.61000001,  0.55340004,  0.49769998,  0.44250000,  0.38810003/
      data ((c2(ip,iw),iw=1,30), ip=10,10)/
     &  -0.1607E-06, -0.4160E-06, -0.9320E-06, -0.1872E-05, -0.3281E-05,
     &  -0.5286E-05, -0.8097E-05, -0.1187E-04, -0.1677E-04, -0.2320E-04,
     &  -0.3190E-04, -0.4402E-04, -0.6081E-04, -0.8441E-04, -0.1162E-03,
     &  -0.1576E-03, -0.2102E-03, -0.2760E-03, -0.3571E-03, -0.4558E-03,
     &  -0.5730E-03, -0.7082E-03, -0.8591E-03, -0.1022E-02, -0.1194E-02,
     &  -0.1368E-02, -0.1533E-02, -0.1671E-02, -0.1775E-02, -0.1843E-02/
      data ((c3(ip,iw),iw=1,30), ip=10,10)/
     &  -0.1164E-09, -0.7276E-10, -0.5530E-09, -0.2270E-08, -0.5093E-08,
     &  -0.9517E-08, -0.1502E-07, -0.2219E-07, -0.3171E-07, -0.4712E-07,
     &  -0.7123E-07, -0.1042E-06, -0.1493E-06, -0.2156E-06, -0.2999E-06,
     &  -0.4027E-06, -0.5243E-06, -0.6616E-06, -0.8125E-06, -0.9691E-06,
     &  -0.1126E-05, -0.1251E-05, -0.1294E-05, -0.1163E-05, -0.7639E-06,
     &  -0.7395E-07,  0.8279E-06,  0.1819E-05,  0.2795E-05,  0.3647E-05/
      data ((c1(ip,iw),iw=1,30), ip=11,11)/
     &   0.99985212,  0.99975210,  0.99960798,  0.99941242,  0.99914628,
     &   0.99876302,  0.99819702,  0.99736100,  0.99616700,  0.99450397,
     &   0.99225003,  0.98920000,  0.98510998,  0.97961998,  0.97220999,
     &   0.96231002,  0.94909000,  0.93155003,  0.90856999,  0.87910002,
     &   0.84219998,  0.79790002,  0.74669999,  0.69080001,  0.63300002,
     &   0.57570004,  0.51950002,  0.46359998,  0.40829998,  0.35450000/
      data ((c2(ip,iw),iw=1,30), ip=11,11)/
     &  -0.1531E-06, -0.3864E-06, -0.8804E-06, -0.1776E-05, -0.3131E-05,
     &  -0.5082E-05, -0.7849E-05, -0.1164E-04, -0.1669E-04, -0.2340E-04,
     &  -0.3261E-04, -0.4546E-04, -0.6380E-04, -0.8932E-04, -0.1237E-03,
     &  -0.1687E-03, -0.2262E-03, -0.2984E-03, -0.3880E-03, -0.4964E-03,
     &  -0.6244E-03, -0.7705E-03, -0.9325E-03, -0.1107E-02, -0.1288E-02,
     &  -0.1466E-02, -0.1623E-02, -0.1746E-02, -0.1831E-02, -0.1875E-02/
      data ((c3(ip,iw),iw=1,30), ip=11,11)/
     &   0.1019E-09, -0.2037E-09, -0.8004E-09, -0.2387E-08, -0.5326E-08,
     &  -0.9764E-08, -0.1576E-07, -0.2256E-07, -0.3180E-07, -0.4616E-07,
     &  -0.7026E-07, -0.1031E-06, -0.1520E-06, -0.2181E-06, -0.3037E-06,
     &  -0.4109E-06, -0.5354E-06, -0.6740E-06, -0.8241E-06, -0.9810E-06,
     &  -0.1126E-05, -0.1221E-05, -0.1200E-05, -0.9678E-06, -0.4500E-06,
     &   0.3236E-06,  0.1256E-05,  0.2259E-05,  0.3206E-05,  0.3978E-05/
      data ((c1(ip,iw),iw=1,30), ip=12,12)/
     &   0.99985027,  0.99974507,  0.99959022,  0.99937689,  0.99907988,
     &   0.99865198,  0.99801201,  0.99706602,  0.99569201,  0.99377203,
     &   0.99115402,  0.98762000,  0.98286003,  0.97640002,  0.96771997,
     &   0.95604998,  0.94045001,  0.91979003,  0.89289999,  0.85879999,
     &   0.81700003,  0.76800001,  0.71340001,  0.65579998,  0.59810001,
     &   0.54139996,  0.48519999,  0.42909998,  0.37410003,  0.32190001/
      data ((c2(ip,iw),iw=1,30), ip=12,12)/
     &  -0.1340E-06, -0.3478E-06, -0.8189E-06, -0.1653E-05, -0.2944E-05,
     &  -0.4852E-05, -0.7603E-05, -0.1150E-04, -0.1682E-04, -0.2400E-04,
     &  -0.3390E-04, -0.4799E-04, -0.6807E-04, -0.9596E-04, -0.1338E-03,
     &  -0.1833E-03, -0.2471E-03, -0.3275E-03, -0.4268E-03, -0.5466E-03,
     &  -0.6862E-03, -0.8439E-03, -0.1017E-02, -0.1201E-02, -0.1389E-02,
     &  -0.1563E-02, -0.1706E-02, -0.1809E-02, -0.1872E-02, -0.1890E-02/
      data ((c3(ip,iw),iw=1,30), ip=12,12)/
     &  -0.1455E-10, -0.1892E-09, -0.8295E-09, -0.2547E-08, -0.5544E-08,
     &  -0.1014E-07, -0.1605E-07, -0.2341E-07, -0.3156E-07, -0.4547E-07,
     &  -0.6749E-07, -0.1034E-06, -0.1550E-06, -0.2230E-06, -0.3130E-06,
     &  -0.4219E-06, -0.5469E-06, -0.6922E-06, -0.8448E-06, -0.9937E-06,
     &  -0.1118E-05, -0.1166E-05, -0.1054E-05, -0.6926E-06, -0.7180E-07,
     &   0.7515E-06,  0.1709E-05,  0.2703E-05,  0.3593E-05,  0.4232E-05/
      data ((c1(ip,iw),iw=1,30), ip=13,13)/
     &   0.99984729,  0.99973530,  0.99956691,  0.99932659,  0.99898797,
     &   0.99849701,  0.99776399,  0.99667102,  0.99507397,  0.99283201,
     &   0.98977000,  0.98563999,  0.98001999,  0.97241002,  0.96213001,
     &   0.94830000,  0.92980999,  0.90546000,  0.87409997,  0.83510000,
     &   0.78850001,  0.73549998,  0.67850000,  0.62049997,  0.56340003,
     &   0.50699997,  0.45050001,  0.39450002,  0.34060001,  0.29079998/
      data ((c2(ip,iw),iw=1,30), ip=13,13)/
     &  -0.1163E-06, -0.3048E-06, -0.7186E-06, -0.1495E-05, -0.2726E-05,
     &  -0.4588E-05, -0.7396E-05, -0.1152E-04, -0.1725E-04, -0.2514E-04,
     &  -0.3599E-04, -0.5172E-04, -0.7403E-04, -0.1051E-03, -0.1469E-03,
     &  -0.2023E-03, -0.2735E-03, -0.3637E-03, -0.4746E-03, -0.6067E-03,
     &  -0.7586E-03, -0.9281E-03, -0.1112E-02, -0.1304E-02, -0.1491E-02,
     &  -0.1653E-02, -0.1777E-02, -0.1860E-02, -0.1896E-02, -0.1891E-02/
      data ((c3(ip,iw),iw=1,30), ip=13,13)/
     &  -0.1455E-09, -0.2765E-09, -0.9750E-09, -0.2794E-08, -0.5413E-08,
     &  -0.1048E-07, -0.1625E-07, -0.2344E-07, -0.3105E-07, -0.4304E-07,
     &  -0.6608E-07, -0.1057E-06, -0.1587E-06, -0.2308E-06, -0.3235E-06,
     &  -0.4373E-06, -0.5687E-06, -0.7156E-06, -0.8684E-06, -0.1007E-05,
     &  -0.1094E-05, -0.1062E-05, -0.8273E-06, -0.3485E-06,  0.3463E-06,
     &   0.1206E-05,  0.2173E-05,  0.3132E-05,  0.3919E-05,  0.4370E-05/
      data ((c1(ip,iw),iw=1,30), ip=14,14)/
     &   0.99984348,  0.99972272,  0.99953479,  0.99926043,  0.99886698,
     &   0.99829400,  0.99744201,  0.99615997,  0.99429500,  0.99166000,
     &   0.98806000,  0.98316997,  0.97649997,  0.96748000,  0.95525998,
     &   0.93878001,  0.91687000,  0.88830000,  0.85220003,  0.80820000,
     &   0.75699997,  0.70099998,  0.64300001,  0.58550000,  0.52890003,
     &   0.47219998,  0.41560000,  0.36040002,  0.30849999,  0.26169997/
      data ((c2(ip,iw),iw=1,30), ip=14,14)/
     &  -0.8581E-07, -0.2557E-06, -0.6103E-06, -0.1305E-05, -0.2472E-05,
     &  -0.4334E-05, -0.7233E-05, -0.1167E-04, -0.1806E-04, -0.2679E-04,
     &  -0.3933E-04, -0.5705E-04, -0.8194E-04, -0.1165E-03, -0.1637E-03,
     &  -0.2259E-03, -0.3068E-03, -0.4082E-03, -0.5318E-03, -0.6769E-03,
     &  -0.8415E-03, -0.1023E-02, -0.1216E-02, -0.1410E-02, -0.1588E-02,
     &  -0.1733E-02, -0.1837E-02, -0.1894E-02, -0.1904E-02, -0.1881E-02/
      data ((c3(ip,iw),iw=1,30), ip=14,14)/
     &  -0.2037E-09, -0.4220E-09, -0.1091E-08, -0.2896E-08, -0.5821E-08,
     &  -0.1052E-07, -0.1687E-07, -0.2353E-07, -0.3193E-07, -0.4254E-07,
     &  -0.6685E-07, -0.1072E-06, -0.1638E-06, -0.2427E-06, -0.3421E-06,
     &  -0.4600E-06, -0.5946E-06, -0.7472E-06, -0.8958E-06, -0.1009E-05,
     &  -0.1032E-05, -0.8919E-06, -0.5224E-06,  0.5218E-07,  0.7886E-06,
     &   0.1672E-05,  0.2626E-05,  0.3513E-05,  0.4138E-05,  0.4379E-05/
      data ((c1(ip,iw),iw=1,30), ip=15,15)/
     &   0.99983788,  0.99970680,  0.99949580,  0.99917668,  0.99871200,
     &   0.99803603,  0.99703097,  0.99552703,  0.99333203,  0.99023402,
     &   0.98597997,  0.98013997,  0.97223002,  0.96145999,  0.94686002,
     &   0.92727000,  0.90142000,  0.86820000,  0.82700002,  0.77820003,
     &   0.72350001,  0.66569996,  0.60769999,  0.55089998,  0.49430001,
     &   0.43739998,  0.38110000,  0.32749999,  0.27840000,  0.23479998/
      data ((c2(ip,iw),iw=1,30), ip=15,15)/
     &  -0.8246E-07, -0.2070E-06, -0.4895E-06, -0.1106E-05, -0.2216E-05,
     &  -0.4077E-05, -0.7150E-05, -0.1202E-04, -0.1920E-04, -0.2938E-04,
     &  -0.4380E-04, -0.6390E-04, -0.9209E-04, -0.1310E-03, -0.1843E-03,
     &  -0.2554E-03, -0.3468E-03, -0.4611E-03, -0.5982E-03, -0.7568E-03,
     &  -0.9340E-03, -0.1126E-02, -0.1324E-02, -0.1514E-02, -0.1676E-02,
     &  -0.1801E-02, -0.1881E-02, -0.1911E-02, -0.1900E-02, -0.1867E-02/
      data ((c3(ip,iw),iw=1,30), ip=15,15)/
     &  -0.1601E-09, -0.3492E-09, -0.1019E-08, -0.2634E-08, -0.5632E-08,
     &  -0.1065E-07, -0.1746E-07, -0.2542E-07, -0.3206E-07, -0.4390E-07,
     &  -0.6956E-07, -0.1093E-06, -0.1729E-06, -0.2573E-06, -0.3612E-06,
     &  -0.4904E-06, -0.6342E-06, -0.7834E-06, -0.9175E-06, -0.9869E-06,
     &  -0.9164E-06, -0.6386E-06, -0.1544E-06,  0.4798E-06,  0.1252E-05,
     &   0.2137E-05,  0.3043E-05,  0.3796E-05,  0.4211E-05,  0.4332E-05/
      data ((c1(ip,iw),iw=1,30), ip=16,16)/
     &   0.99983227,  0.99968958,  0.99945217,  0.99907941,  0.99852598,
     &   0.99772000,  0.99652398,  0.99475902,  0.99218899,  0.98856002,
     &   0.98348999,  0.97653997,  0.96708000,  0.95420998,  0.93677002,
     &   0.91352999,  0.88330001,  0.84509999,  0.79900002,  0.74599999,
     &   0.68879998,  0.63049996,  0.57319999,  0.51660001,  0.45969999,
     &   0.40289998,  0.34780002,  0.29650003,  0.25070000,  0.20959997/
      data ((c2(ip,iw),iw=1,30), ip=16,16)/
     &  -0.7004E-07, -0.1592E-06, -0.3936E-06, -0.9145E-06, -0.1958E-05,
     &  -0.3850E-05, -0.7093E-05, -0.1252E-04, -0.2066E-04, -0.3271E-04,
     &  -0.4951E-04, -0.7268E-04, -0.1045E-03, -0.1487E-03, -0.2092E-03,
     &  -0.2899E-03, -0.3936E-03, -0.5215E-03, -0.6729E-03, -0.8454E-03,
     &  -0.1035E-02, -0.1235E-02, -0.1432E-02, -0.1608E-02, -0.1751E-02,
     &  -0.1854E-02, -0.1907E-02, -0.1913E-02, -0.1888E-02, -0.1857E-02/
      data ((c3(ip,iw),iw=1,30), ip=16,16)/
     &  -0.2328E-09, -0.3347E-09, -0.9750E-09, -0.2314E-08, -0.5166E-08,
     &  -0.1052E-07, -0.1726E-07, -0.2605E-07, -0.3532E-07, -0.4949E-07,
     &  -0.7229E-07, -0.1133E-06, -0.1799E-06, -0.2725E-06, -0.3881E-06,
     &  -0.5249E-06, -0.6763E-06, -0.8227E-06, -0.9279E-06, -0.9205E-06,
     &  -0.7228E-06, -0.3109E-06,  0.2583E-06,  0.9390E-06,  0.1726E-05,
     &   0.2579E-05,  0.3376E-05,  0.3931E-05,  0.4161E-05,  0.4369E-05/
      data ((c1(ip,iw),iw=1,30), ip=17,17)/
     &   0.99982637,  0.99967217,  0.99940813,  0.99897701,  0.99831802,
     &   0.99734300,  0.99592501,  0.99385202,  0.99086499,  0.98659998,
     &   0.98057997,  0.97229999,  0.96098000,  0.94555002,  0.92479002,
     &   0.89740002,  0.86240000,  0.81919998,  0.76859999,  0.71249998,
     &   0.65419996,  0.59630001,  0.53950000,  0.48259997,  0.42549998,
     &   0.36940002,  0.31629997,  0.26810002,  0.22520000,  0.18580002/
      data ((c2(ip,iw),iw=1,30), ip=17,17)/
     &  -0.6526E-07, -0.1282E-06, -0.3076E-06, -0.7454E-06, -0.1685E-05,
     &  -0.3600E-05, -0.7071E-05, -0.1292E-04, -0.2250E-04, -0.3665E-04,
     &  -0.5623E-04, -0.8295E-04, -0.1195E-03, -0.1696E-03, -0.2385E-03,
     &  -0.3298E-03, -0.4465E-03, -0.5887E-03, -0.7546E-03, -0.9408E-03,
     &  -0.1141E-02, -0.1345E-02, -0.1533E-02, -0.1691E-02, -0.1813E-02,
     &  -0.1889E-02, -0.1916E-02, -0.1904E-02, -0.1877E-02, -0.1850E-02/
      data ((c3(ip,iw),iw=1,30), ip=17,17)/
     &  -0.1746E-09, -0.2037E-09, -0.8149E-09, -0.2095E-08, -0.4889E-08,
     &  -0.9517E-08, -0.1759E-07, -0.2740E-07, -0.4147E-07, -0.5774E-07,
     &  -0.7909E-07, -0.1199E-06, -0.1877E-06, -0.2859E-06, -0.4137E-06,
     &  -0.5649E-06, -0.7218E-06, -0.8516E-06, -0.9022E-06, -0.7905E-06,
     &  -0.4531E-06,  0.6917E-07,  0.7009E-06,  0.1416E-05,  0.2194E-05,
     &   0.2963E-05,  0.3578E-05,  0.3900E-05,  0.4094E-05,  0.4642E-05/
      data ((c1(ip,iw),iw=1,30), ip=18,18)/
     &   0.99982101,  0.99965781,  0.99936712,  0.99887502,  0.99809802,
     &   0.99692702,  0.99523401,  0.99281400,  0.98935997,  0.98435003,
     &   0.97728002,  0.96740997,  0.95381999,  0.93539000,  0.91082001,
     &   0.87889999,  0.83889997,  0.79100001,  0.73660004,  0.67879999,
     &   0.62049997,  0.56330001,  0.50629997,  0.44900000,  0.39209998,
     &   0.33749998,  0.28729999,  0.24229997,  0.20150000,  0.16280001/
      data ((c2(ip,iw),iw=1,30), ip=18,18)/
     &  -0.6477E-07, -0.1243E-06, -0.2536E-06, -0.6173E-06, -0.1495E-05,
     &  -0.3353E-05, -0.6919E-05, -0.1337E-04, -0.2418E-04, -0.4049E-04,
     &  -0.6354E-04, -0.9455E-04, -0.1367E-03, -0.1942E-03, -0.2717E-03,
     &  -0.3744E-03, -0.5042E-03, -0.6609E-03, -0.8416E-03, -0.1041E-02,
     &  -0.1249E-02, -0.1448E-02, -0.1622E-02, -0.1760E-02, -0.1857E-02,
     &  -0.1906E-02, -0.1911E-02, -0.1892E-02, -0.1870E-02, -0.1844E-02/
      data ((c3(ip,iw),iw=1,30), ip=18,18)/
     &  -0.5821E-10, -0.2328E-09, -0.6985E-09, -0.1368E-08, -0.4351E-08,
     &  -0.8993E-08, -0.1579E-07, -0.2916E-07, -0.4904E-07, -0.7010E-07,
     &  -0.9623E-07, -0.1332E-06, -0.1928E-06, -0.2977E-06, -0.4371E-06,
     &  -0.5992E-06, -0.7586E-06, -0.8580E-06, -0.8238E-06, -0.5811E-06,
     &  -0.1298E-06,  0.4702E-06,  0.1162E-05,  0.1905E-05,  0.2632E-05,
     &   0.3247E-05,  0.3609E-05,  0.3772E-05,  0.4166E-05,  0.5232E-05/
      data ((c1(ip,iw),iw=1,30), ip=19,19)/
     &   0.99981648,  0.99964571,  0.99933147,  0.99878597,  0.99787998,
     &   0.99649400,  0.99448699,  0.99166602,  0.98762000,  0.98181999,
     &   0.97352999,  0.96183002,  0.94558001,  0.92363000,  0.89480001,
     &   0.85799998,  0.81309998,  0.76100004,  0.70420003,  0.64590001,
     &   0.58840001,  0.53139997,  0.47380000,  0.41619998,  0.36030000,
     &   0.30809999,  0.26109999,  0.21880001,  0.17909998,  0.14080000/
      data ((c2(ip,iw),iw=1,30), ip=19,19)/
     &  -0.7906E-07, -0.1291E-06, -0.2430E-06, -0.5145E-06, -0.1327E-05,
     &  -0.3103E-05, -0.6710E-05, -0.1371E-04, -0.2561E-04, -0.4405E-04,
     &  -0.7051E-04, -0.1070E-03, -0.1560E-03, -0.2217E-03, -0.3090E-03,
     &  -0.4228E-03, -0.5657E-03, -0.7371E-03, -0.9322E-03, -0.1142E-02,
     &  -0.1352E-02, -0.1541E-02, -0.1697E-02, -0.1813E-02, -0.1883E-02,
     &  -0.1906E-02, -0.1898E-02, -0.1882E-02, -0.1866E-02, -0.1832E-02/
      data ((c3(ip,iw),iw=1,30), ip=19,19)/
     &   0.2910E-10,  0.1455E-10, -0.2765E-09, -0.1426E-08, -0.2576E-08,
     &  -0.5923E-08, -0.1429E-07, -0.3159E-07, -0.5441E-07, -0.8367E-07,
     &  -0.1161E-06, -0.1526E-06, -0.2060E-06, -0.3007E-06, -0.4450E-06,
     &  -0.6182E-06, -0.7683E-06, -0.8170E-06, -0.6754E-06, -0.3122E-06,
     &   0.2234E-06,  0.8828E-06,  0.1632E-05,  0.2373E-05,  0.3002E-05,
     &   0.3384E-05,  0.3499E-05,  0.3697E-05,  0.4517E-05,  0.6117E-05/
      data ((c1(ip,iw),iw=1,30), ip=20,20)/
     &   0.99981302,  0.99963689,  0.99930489,  0.99870700,  0.99768901,
     &   0.99608499,  0.99373102,  0.99039900,  0.98566997,  0.97895002,
     &   0.96930999,  0.95548999,  0.93621999,  0.91029000,  0.87669998,
     &   0.83490002,  0.78549999,  0.73019999,  0.67240000,  0.61469996,
     &   0.55779999,  0.50029999,  0.44220001,  0.38489997,  0.33069998,
     &   0.28149998,  0.23760003,  0.19690001,  0.15759999,  0.11989999/
      data ((c2(ip,iw),iw=1,30), ip=20,20)/
     &  -0.7762E-07, -0.1319E-06, -0.2315E-06, -0.4780E-06, -0.1187E-05,
     &  -0.2750E-05, -0.6545E-05, -0.1393E-04, -0.2645E-04, -0.4652E-04,
     &  -0.7657E-04, -0.1190E-03, -0.1766E-03, -0.2520E-03, -0.3499E-03,
     &  -0.4751E-03, -0.6307E-03, -0.8160E-03, -0.1024E-02, -0.1240E-02,
     &  -0.1443E-02, -0.1619E-02, -0.1757E-02, -0.1849E-02, -0.1892E-02,
     &  -0.1896E-02, -0.1886E-02, -0.1878E-02, -0.1861E-02, -0.1807E-02/
      data ((c3(ip,iw),iw=1,30), ip=20,20)/
     &   0.8731E-10, -0.7276E-10, -0.2328E-09, -0.6403E-09, -0.1455E-08,
     &  -0.3827E-08, -0.1270E-07, -0.3014E-07, -0.5594E-07, -0.9677E-07,
     &  -0.1422E-06, -0.1823E-06, -0.2296E-06, -0.3094E-06, -0.4399E-06,
     &  -0.6008E-06, -0.7239E-06, -0.7014E-06, -0.4562E-06, -0.7778E-08,
     &   0.5785E-06,  0.1291E-05,  0.2072E-05,  0.2783E-05,  0.3247E-05,
     &   0.3358E-05,  0.3364E-05,  0.3847E-05,  0.5194E-05,  0.7206E-05/
      data ((c1(ip,iw),iw=1,30), ip=21,21)/
     &   0.99981070,  0.99962878,  0.99928439,  0.99864298,  0.99752903,
     &   0.99573100,  0.99301797,  0.98905998,  0.98354000,  0.97570997,
     &   0.96449000,  0.94837999,  0.92576003,  0.89539999,  0.85680002,
     &   0.81000000,  0.75660002,  0.69949996,  0.64199996,  0.58529997,
     &   0.52829999,  0.47020000,  0.41200000,  0.35570002,  0.30400002,
     &   0.25800002,  0.21609998,  0.17610002,  0.13709998,  0.10020000/
      data ((c2(ip,iw),iw=1,30), ip=21,21)/
     &  -0.1010E-06, -0.1533E-06, -0.2347E-06, -0.4535E-06, -0.1029E-05,
     &  -0.2530E-05, -0.6335E-05, -0.1381E-04, -0.2681E-04, -0.4777E-04,
     &  -0.8083E-04, -0.1296E-03, -0.1966E-03, -0.2836E-03, -0.3937E-03,
     &  -0.5313E-03, -0.6995E-03, -0.8972E-03, -0.1113E-02, -0.1327E-02,
     &  -0.1520E-02, -0.1681E-02, -0.1800E-02, -0.1867E-02, -0.1887E-02,
     &  -0.1884E-02, -0.1881E-02, -0.1879E-02, -0.1849E-02, -0.1764E-02/
      data ((c3(ip,iw),iw=1,30), ip=21,21)/
     &   0.8731E-10,  0.1310E-09, -0.2474E-09, -0.2619E-09,  0.8295E-09,
     &  -0.1979E-08, -0.1141E-07, -0.2621E-07, -0.5799E-07, -0.1060E-06,
     &  -0.1621E-06, -0.2281E-06, -0.2793E-06, -0.3335E-06, -0.4277E-06,
     &  -0.5429E-06, -0.5970E-06, -0.4872E-06, -0.1775E-06,  0.3028E-06,
     &   0.9323E-06,  0.1680E-05,  0.2452E-05,  0.3063E-05,  0.3299E-05,
     &   0.3219E-05,  0.3369E-05,  0.4332E-05,  0.6152E-05,  0.8413E-05/
      data ((c1(ip,iw),iw=1,30), ip=22,22)/
     &   0.99980962,  0.99962330,  0.99926400,  0.99858999,  0.99741602,
     &   0.99547201,  0.99236798,  0.98776001,  0.98124999,  0.97210997,
     &   0.95902997,  0.94033003,  0.91415000,  0.87919998,  0.83529997,
     &   0.78380001,  0.72749996,  0.66990000,  0.61339998,  0.55720001,
     &   0.49980003,  0.44129997,  0.38360000,  0.32929999,  0.28070003,
     &   0.23710001,  0.19620001,  0.15619999,  0.11769998,  0.08200002/
      data ((c2(ip,iw),iw=1,30), ip=22,22)/
     &  -0.1258E-06, -0.1605E-06, -0.2581E-06, -0.4286E-06, -0.8321E-06,
     &  -0.2392E-05, -0.6163E-05, -0.1358E-04, -0.2646E-04, -0.4792E-04,
     &  -0.8284E-04, -0.1369E-03, -0.2138E-03, -0.3141E-03, -0.4393E-03,
     &  -0.5917E-03, -0.7731E-03, -0.9796E-03, -0.1195E-02, -0.1399E-02,
     &  -0.1579E-02, -0.1725E-02, -0.1822E-02, -0.1867E-02, -0.1877E-02,
     &  -0.1879E-02, -0.1886E-02, -0.1879E-02, -0.1825E-02, -0.1706E-02/
      data ((c3(ip,iw),iw=1,30), ip=22,22)/
     &  -0.8731E-10,  0.2910E-10,  0.7276E-10,  0.1281E-08,  0.1222E-08,
     &  -0.1935E-08, -0.8004E-08, -0.2258E-07, -0.5428E-07, -0.1085E-06,
     &  -0.1835E-06, -0.2716E-06, -0.3446E-06, -0.3889E-06, -0.4203E-06,
     &  -0.4394E-06, -0.3716E-06, -0.1677E-06,  0.1622E-06,  0.6327E-06,
     &   0.1275E-05,  0.2018E-05,  0.2716E-05,  0.3137E-05,  0.3136E-05,
     &   0.3078E-05,  0.3649E-05,  0.5152E-05,  0.7315E-05,  0.9675E-05/
      data ((c1(ip,iw),iw=1,30), ip=23,23)/
     &   0.99980921,  0.99961692,  0.99924570,  0.99854898,  0.99734801,
     &   0.99527103,  0.99182302,  0.98655999,  0.97895002,  0.96814001,
     &   0.95284998,  0.93124998,  0.90130001,  0.86170000,  0.81290001,
     &   0.75740004,  0.69920003,  0.64199996,  0.58640003,  0.53020000,
     &   0.47240001,  0.41399997,  0.35780001,  0.30650002,  0.26069999,
     &   0.21850002,  0.17750001,  0.13739997,  0.09950000,  0.06540000/
      data ((c2(ip,iw),iw=1,30), ip=23,23)/
     &  -0.1434E-06, -0.1676E-06, -0.2699E-06, -0.2859E-06, -0.7542E-06,
     &  -0.2273E-05, -0.5898E-05, -0.1292E-04, -0.2538E-04, -0.4649E-04,
     &  -0.8261E-04, -0.1405E-03, -0.2259E-03, -0.3407E-03, -0.4845E-03,
     &  -0.6561E-03, -0.8524E-03, -0.1062E-02, -0.1266E-02, -0.1456E-02,
     &  -0.1621E-02, -0.1748E-02, -0.1823E-02, -0.1854E-02, -0.1868E-02,
     &  -0.1886E-02, -0.1899E-02, -0.1876E-02, -0.1790E-02, -0.1636E-02/
      data ((c3(ip,iw),iw=1,30), ip=23,23)/
     &  -0.1892E-09, -0.2474E-09,  0.1892E-09,  0.2561E-08,  0.4366E-09,
     &  -0.1499E-08, -0.4336E-08, -0.1740E-07, -0.5233E-07, -0.1055E-06,
     &  -0.1940E-06, -0.3113E-06, -0.4161E-06, -0.4620E-06, -0.4316E-06,
     &  -0.3031E-06, -0.5438E-07,  0.2572E-06,  0.5773E-06,  0.1008E-05,
     &   0.1609E-05,  0.2290E-05,  0.2817E-05,  0.2940E-05,  0.2803E-05,
     &   0.3061E-05,  0.4235E-05,  0.6225E-05,  0.8615E-05,  0.1095E-04/
      data ((c1(ip,iw),iw=1,30), ip=24,24)/
     &   0.99980992,  0.99961102,  0.99922198,  0.99852699,  0.99732202,
     &   0.99510902,  0.99140203,  0.98550999,  0.97672999,  0.96399999,
     &   0.94602001,  0.92101002,  0.88709998,  0.84310001,  0.79020000,
     &   0.73189998,  0.67299998,  0.61619997,  0.56060004,  0.50400001,
     &   0.44610000,  0.38880002,  0.33530003,  0.28740001,  0.24390000,
     &   0.20179999,  0.16009998,  0.11979997,  0.08260000,  0.05049998/
      data ((c2(ip,iw),iw=1,30), ip=24,24)/
     &  -0.1529E-06, -0.2005E-06, -0.2861E-06, -0.1652E-06, -0.6334E-06,
     &  -0.1965E-05, -0.5437E-05, -0.1182E-04, -0.2344E-04, -0.4384E-04,
     &  -0.7982E-04, -0.1398E-03, -0.2321E-03, -0.3616E-03, -0.5274E-03,
     &  -0.7239E-03, -0.9363E-03, -0.1142E-02, -0.1328E-02, -0.1499E-02,
     &  -0.1645E-02, -0.1748E-02, -0.1804E-02, -0.1834E-02, -0.1867E-02,
     &  -0.1903E-02, -0.1914E-02, -0.1866E-02, -0.1746E-02, -0.1558E-02/
      data ((c3(ip,iw),iw=1,30), ip=24,24)/
     &  -0.3638E-09, -0.9313E-09,  0.1703E-08,  0.2081E-08, -0.1251E-08,
     &  -0.1208E-08, -0.6883E-08, -0.1608E-07, -0.4559E-07, -0.1047E-06,
     &  -0.2040E-06, -0.3312E-06, -0.4624E-06, -0.5198E-06, -0.4326E-06,
     &  -0.1452E-06,  0.3003E-06,  0.7455E-06,  0.1102E-05,  0.1470E-05,
     &   0.1957E-05,  0.2474E-05,  0.2691E-05,  0.2484E-05,  0.2414E-05,
     &   0.3232E-05,  0.5050E-05,  0.7455E-05,  0.9997E-05,  0.1217E-04/
      data ((c1(ip,iw),iw=1,30), ip=25,25)/
     &   0.99980998,  0.99960178,  0.99920201,  0.99852800,  0.99729002,
     &   0.99498200,  0.99102801,  0.98461998,  0.97465998,  0.95982999,
     &   0.93866003,  0.90968001,  0.87140000,  0.82340002,  0.76770002,
     &   0.70860004,  0.64999998,  0.59290004,  0.53610003,  0.47860003,
     &   0.42110002,  0.36610001,  0.31639999,  0.27200001,  0.22960001,
     &   0.18690002,  0.14429998,  0.10380000,  0.06739998,  0.03740001/
      data ((c2(ip,iw),iw=1,30), ip=25,25)/
     &  -0.1453E-06, -0.2529E-06, -0.1807E-06, -0.1109E-06, -0.4469E-06,
     &  -0.1885E-05, -0.4590E-05, -0.1043E-04, -0.2057E-04, -0.3951E-04,
     &  -0.7466E-04, -0.1356E-03, -0.2341E-03, -0.3783E-03, -0.5688E-03,
     &  -0.7935E-03, -0.1021E-02, -0.1219E-02, -0.1388E-02, -0.1535E-02,
     &  -0.1653E-02, -0.1726E-02, -0.1768E-02, -0.1813E-02, -0.1874E-02,
     &  -0.1925E-02, -0.1927E-02, -0.1851E-02, -0.1697E-02, -0.1478E-02/
      data ((c3(ip,iw),iw=1,30), ip=25,25)/
     &  -0.6257E-09, -0.1382E-08,  0.2095E-08,  0.1863E-08, -0.1834E-08,
     &  -0.2125E-08, -0.6985E-08, -0.1634E-07, -0.4128E-07, -0.9924E-07,
     &  -0.1938E-06, -0.3275E-06, -0.4556E-06, -0.5046E-06, -0.3633E-06,
     &   0.2484E-07,  0.6195E-06,  0.1249E-05,  0.1731E-05,  0.2053E-05,
     &   0.2358E-05,  0.2569E-05,  0.2342E-05,  0.1883E-05,  0.2103E-05,
     &   0.3570E-05,  0.5973E-05,  0.8752E-05,  0.1140E-04,  0.1328E-04/
      data ((c1(ip,iw),iw=1,30), ip=26,26)/
     &   0.99980712,  0.99958581,  0.99919039,  0.99854302,  0.99724799,
     &   0.99486500,  0.99071401,  0.98379999,  0.97279000,  0.95585001,
     &   0.93112999,  0.89749998,  0.85460001,  0.80320001,  0.74660003,
     &   0.68869996,  0.63100004,  0.57249999,  0.51320004,  0.45450002,
     &   0.39810002,  0.34649998,  0.30119997,  0.25950003,  0.21740001,
     &   0.17379999,  0.13029999,  0.08950001,  0.05400002,  0.02640003/
      data ((c2(ip,iw),iw=1,30), ip=26,26)/
     &  -0.1257E-06, -0.2495E-06, -0.1334E-06, -0.8414E-07, -0.1698E-06,
     &  -0.1346E-05, -0.3692E-05, -0.8625E-05, -0.1750E-04, -0.3483E-04,
     &  -0.6843E-04, -0.1305E-03, -0.2362E-03, -0.3971E-03, -0.6127E-03,
     &  -0.8621E-03, -0.1101E-02, -0.1297E-02, -0.1452E-02, -0.1570E-02,
     &  -0.1647E-02, -0.1688E-02, -0.1727E-02, -0.1797E-02, -0.1887E-02,
     &  -0.1947E-02, -0.1935E-02, -0.1833E-02, -0.1647E-02, -0.1401E-02/
      data ((c3(ip,iw),iw=1,30), ip=26,26)/
     &  -0.1222E-08, -0.1164E-09,  0.2285E-08,  0.2037E-09,  0.5675E-09,
     &  -0.5239E-08, -0.9211E-08, -0.1483E-07, -0.3981E-07, -0.9641E-07,
     &  -0.1717E-06, -0.2796E-06, -0.3800E-06, -0.3762E-06, -0.1936E-06,
     &   0.1920E-06,  0.8335E-06,  0.1691E-05,  0.2415E-05,  0.2767E-05,
     &   0.2823E-05,  0.2551E-05,  0.1839E-05,  0.1314E-05,  0.1960E-05,
     &   0.4003E-05,  0.6909E-05,  0.1004E-04,  0.1273E-04,  0.1423E-04/
      data ((o1(ip,iw),iw=1,21), ip= 1, 1)/
     &   0.99999344,  0.99998689,  0.99997336,  0.99994606,  0.99989170,
     &   0.99978632,  0.99957907,  0.99918377,  0.99844402,  0.99712098,
     &   0.99489498,  0.99144602,  0.98655999,  0.98008001,  0.97165000,
     &   0.96043998,  0.94527000,  0.92462999,  0.89709997,  0.86180001,
     &   0.81800002/
      data ((o2(ip,iw),iw=1,21), ip= 1, 1)/
     &   0.6531E-10,  0.5926E-10, -0.1646E-09, -0.1454E-08, -0.7376E-08,
     &  -0.2968E-07, -0.1071E-06, -0.3584E-06, -0.1125E-05, -0.3289E-05,
     &  -0.8760E-05, -0.2070E-04, -0.4259E-04, -0.7691E-04, -0.1264E-03,
     &  -0.1957E-03, -0.2895E-03, -0.4107E-03, -0.5588E-03, -0.7300E-03,
     &  -0.9199E-03/
      data ((o3(ip,iw),iw=1,21), ip= 1, 1)/
     &  -0.2438E-10, -0.4826E-10, -0.9474E-10, -0.1828E-09, -0.3406E-09,
     &  -0.6223E-09, -0.1008E-08, -0.1412E-08, -0.1244E-08,  0.8485E-09,
     &   0.6343E-08,  0.1201E-07,  0.2838E-08, -0.4024E-07, -0.1257E-06,
     &  -0.2566E-06, -0.4298E-06, -0.6184E-06, -0.7657E-06, -0.8153E-06,
     &  -0.7552E-06/
      data ((o1(ip,iw),iw=1,21), ip= 2, 2)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994606,  0.99989170,
     &   0.99978632,  0.99957907,  0.99918377,  0.99844402,  0.99712098,
     &   0.99489498,  0.99144298,  0.98654997,  0.98006999,  0.97162998,
     &   0.96042001,  0.94520003,  0.92449999,  0.89690000,  0.86140001,
     &   0.81739998/
      data ((o2(ip,iw),iw=1,21), ip= 2, 2)/
     &   0.6193E-10,  0.5262E-10, -0.1774E-09, -0.1478E-08, -0.7416E-08,
     &  -0.2985E-07, -0.1071E-06, -0.3584E-06, -0.1124E-05, -0.3287E-05,
     &  -0.8753E-05, -0.2069E-04, -0.4256E-04, -0.7686E-04, -0.1264E-03,
     &  -0.1956E-03, -0.2893E-03, -0.4103E-03, -0.5580E-03, -0.7285E-03,
     &  -0.9171E-03/
      data ((o3(ip,iw),iw=1,21), ip= 2, 2)/
     &  -0.2436E-10, -0.4822E-10, -0.9466E-10, -0.1827E-09, -0.3404E-09,
     &  -0.6220E-09, -0.1008E-08, -0.1414E-08, -0.1247E-08,  0.8360E-09,
     &   0.6312E-08,  0.1194E-07,  0.2753E-08, -0.4040E-07, -0.1260E-06,
     &  -0.2571E-06, -0.4307E-06, -0.6202E-06, -0.7687E-06, -0.8204E-06,
     &  -0.7636E-06/
      data ((o1(ip,iw),iw=1,21), ip= 3, 3)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994606,  0.99989170,
     &   0.99978632,  0.99957907,  0.99918377,  0.99844402,  0.99712098,
     &   0.99489301,  0.99143898,  0.98654997,  0.98005998,  0.97158998,
     &   0.96035999,  0.94509000,  0.92431998,  0.89660001,  0.86080003,
     &   0.81639999/
      data ((o2(ip,iw),iw=1,21), ip= 3, 3)/
     &   0.5658E-10,  0.4212E-10, -0.1977E-09, -0.1516E-08, -0.7481E-08,
     &  -0.2995E-07, -0.1072E-06, -0.3583E-06, -0.1123E-05, -0.3283E-05,
     &  -0.8744E-05, -0.2067E-04, -0.4252E-04, -0.7679E-04, -0.1262E-03,
     &  -0.1953E-03, -0.2889E-03, -0.4096E-03, -0.5567E-03, -0.7263E-03,
     &  -0.9130E-03/
      data ((o3(ip,iw),iw=1,21), ip= 3, 3)/
     &  -0.2433E-10, -0.4815E-10, -0.9453E-10, -0.1825E-09, -0.3400E-09,
     &  -0.6215E-09, -0.1007E-08, -0.1415E-08, -0.1253E-08,  0.8143E-09,
     &   0.6269E-08,  0.1186E-07,  0.2604E-08, -0.4067E-07, -0.1264E-06,
     &  -0.2579E-06, -0.4321E-06, -0.6229E-06, -0.7732E-06, -0.8277E-06,
     &  -0.7752E-06/
      data ((o1(ip,iw),iw=1,21), ip= 4, 4)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994606,  0.99989200,
     &   0.99978632,  0.99957907,  0.99918377,  0.99844402,  0.99711901,
     &   0.99489301,  0.99143499,  0.98653001,  0.98003000,  0.97153997,
     &   0.96026999,  0.94493997,  0.92404002,  0.89609998,  0.85990000,
     &   0.81480002/
      data ((o2(ip,iw),iw=1,21), ip= 4, 4)/
     &   0.4814E-10,  0.2552E-10, -0.2298E-09, -0.1576E-08, -0.7579E-08,
     &  -0.3009E-07, -0.1074E-06, -0.3581E-06, -0.1122E-05, -0.3278E-05,
     &  -0.8729E-05, -0.2063E-04, -0.4245E-04, -0.7667E-04, -0.1260E-03,
     &  -0.1950E-03, -0.2883E-03, -0.4086E-03, -0.5549E-03, -0.7229E-03,
     &  -0.9071E-03/
      data ((o3(ip,iw),iw=1,21), ip= 4, 4)/
     &  -0.2428E-10, -0.4805E-10, -0.9433E-10, -0.1821E-09, -0.3394E-09,
     &  -0.6206E-09, -0.1008E-08, -0.1416E-08, -0.1261E-08,  0.7860E-09,
     &   0.6188E-08,  0.1171E-07,  0.2389E-08, -0.4109E-07, -0.1271E-06,
     &  -0.2591E-06, -0.4344E-06, -0.6267E-06, -0.7797E-06, -0.8378E-06,
     &  -0.7901E-06/
      data ((o1(ip,iw),iw=1,21), ip= 5, 5)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994606,  0.99989200,
     &   0.99978638,  0.99957907,  0.99918377,  0.99844402,  0.99711901,
     &   0.99488801,  0.99142599,  0.98650998,  0.97999001,  0.97148001,
     &   0.96011001,  0.94467002,  0.92356998,  0.89530003,  0.85860002,
     &   0.81250000/
      data ((o2(ip,iw),iw=1,21), ip= 5, 5)/
     &   0.3482E-10, -0.6492E-12, -0.2805E-09, -0.1671E-08, -0.7740E-08,
     &  -0.3032E-07, -0.1076E-06, -0.3582E-06, -0.1120E-05, -0.3270E-05,
     &  -0.8704E-05, -0.2058E-04, -0.4235E-04, -0.7649E-04, -0.1257E-03,
     &  -0.1945E-03, -0.2874E-03, -0.4070E-03, -0.5521E-03, -0.7181E-03,
     &  -0.8990E-03/
      data ((o3(ip,iw),iw=1,21), ip= 5, 5)/
     &  -0.2419E-10, -0.4788E-10, -0.9401E-10, -0.1815E-09, -0.3385E-09,
     &  -0.6192E-09, -0.1006E-08, -0.1417E-08, -0.1273E-08,  0.7404E-09,
     &   0.6068E-08,  0.1148E-07,  0.2021E-08, -0.4165E-07, -0.1281E-06,
     &  -0.2609E-06, -0.4375E-06, -0.6323E-06, -0.7887E-06, -0.8508E-06,
     &  -0.8067E-06/
      data ((o1(ip,iw),iw=1,21), ip= 6, 6)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994606,  0.99989200,
     &   0.99978638,  0.99957931,  0.99918377,  0.99844301,  0.99711698,
     &   0.99488401,  0.99141300,  0.98648000,  0.97992003,  0.97135001,
     &   0.95989001,  0.94428003,  0.92286998,  0.89410001,  0.85640001,
     &   0.80890000/
      data ((o2(ip,iw),iw=1,21), ip= 6, 6)/
     &   0.1388E-10, -0.4180E-10, -0.3601E-09, -0.1820E-08, -0.7993E-08,
     &  -0.3068E-07, -0.1081E-06, -0.3580E-06, -0.1117E-05, -0.3257E-05,
     &  -0.8667E-05, -0.2049E-04, -0.4218E-04, -0.7620E-04, -0.1253E-03,
     &  -0.1937E-03, -0.2860E-03, -0.4047E-03, -0.5481E-03, -0.7115E-03,
     &  -0.8885E-03/
      data ((o3(ip,iw),iw=1,21), ip= 6, 6)/
     &  -0.2406E-10, -0.4762E-10, -0.9351E-10, -0.1806E-09, -0.3370E-09,
     &  -0.6170E-09, -0.1004E-08, -0.1417E-08, -0.1297E-08,  0.6738E-09,
     &   0.5895E-08,  0.1113E-07,  0.1466E-08, -0.4265E-07, -0.1298E-06,
     &  -0.2636E-06, -0.4423E-06, -0.6402E-06, -0.8005E-06, -0.8658E-06,
     &  -0.8222E-06/
      data ((o1(ip,iw),iw=1,21), ip= 7, 7)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994630,  0.99989200,
     &   0.99978638,  0.99957931,  0.99918360,  0.99844301,  0.99711502,
     &   0.99487501,  0.99138802,  0.98642999,  0.97982001,  0.97114998,
     &   0.95954001,  0.94363999,  0.92176998,  0.89219999,  0.85329998,
     &   0.80379999/
      data ((o2(ip,iw),iw=1,21), ip= 7, 7)/
     &  -0.1889E-10, -0.1062E-09, -0.4847E-09, -0.2053E-08, -0.8389E-08,
     &  -0.3140E-07, -0.1089E-06, -0.3577E-06, -0.1112E-05, -0.3236E-05,
     &  -0.8607E-05, -0.2035E-04, -0.4192E-04, -0.7576E-04, -0.1245E-03,
     &  -0.1925E-03, -0.2840E-03, -0.4013E-03, -0.5427E-03, -0.7029E-03,
     &  -0.8756E-03/
      data ((o3(ip,iw),iw=1,21), ip= 7, 7)/
     &  -0.2385E-10, -0.4722E-10, -0.9273E-10, -0.1791E-09, -0.3348E-09,
     &  -0.6121E-09, -0.9974E-09, -0.1422E-08, -0.1326E-08,  0.5603E-09,
     &   0.5604E-08,  0.1061E-07,  0.6106E-09, -0.4398E-07, -0.1321E-06,
     &  -0.2676E-06, -0.4490E-06, -0.6507E-06, -0.8145E-06, -0.8801E-06,
     &  -0.8311E-06/
      data ((o1(ip,iw),iw=1,21), ip= 8, 8)/
     &   0.99999344,  0.99998689,  0.99997348,  0.99994630,  0.99989229,
     &   0.99978650,  0.99957931,  0.99918288,  0.99844098,  0.99711001,
     &   0.99486202,  0.99135500,  0.98635000,  0.97965997,  0.97083998,
     &   0.95898998,  0.94266999,  0.92009997,  0.88929999,  0.84860003,
     &   0.79640001/
      data ((o2(ip,iw),iw=1,21), ip= 8, 8)/
     &  -0.6983E-10, -0.2063E-09, -0.6785E-09, -0.2416E-08, -0.9000E-08,
     &  -0.3243E-07, -0.1100E-06, -0.3574E-06, -0.1104E-05, -0.3205E-05,
     &  -0.8516E-05, -0.2014E-04, -0.4151E-04, -0.7508E-04, -0.1234E-03,
     &  -0.1907E-03, -0.2811E-03, -0.3966E-03, -0.5355E-03, -0.6924E-03,
     &  -0.8613E-03/
      data ((o3(ip,iw),iw=1,21), ip= 8, 8)/
     &  -0.2353E-10, -0.4659E-10, -0.9153E-10, -0.1769E-09, -0.3313E-09,
     &  -0.6054E-09, -0.9899E-09, -0.1430E-08, -0.1375E-08,  0.3874E-09,
     &   0.5171E-08,  0.9807E-08, -0.7345E-09, -0.4604E-07, -0.1356E-06,
     &  -0.2731E-06, -0.4577E-06, -0.6632E-06, -0.8284E-06, -0.8894E-06,
     &  -0.8267E-06/
      data ((o1(ip,iw),iw=1,21), ip= 9, 9)/
     &   0.99999344,  0.99998689,  0.99997360,  0.99994630,  0.99989229,
     &   0.99978650,  0.99957961,  0.99918252,  0.99843901,  0.99710202,
     &   0.99484003,  0.99130303,  0.98623002,  0.97940999,  0.97038001,
     &   0.95815003,  0.94119000,  0.91755998,  0.88510001,  0.84189999,
     &   0.78610003/
      data ((o2(ip,iw),iw=1,21), ip= 9, 9)/
     &  -0.1481E-09, -0.3601E-09, -0.9762E-09, -0.2973E-08, -0.1014E-07,
     &  -0.3421E-07, -0.1121E-06, -0.3569E-06, -0.1092E-05, -0.3156E-05,
     &  -0.8375E-05, -0.1981E-04, -0.4090E-04, -0.7405E-04, -0.1218E-03,
     &  -0.1881E-03, -0.2770E-03, -0.3906E-03, -0.5269E-03, -0.6810E-03,
     &  -0.8471E-03/
      data ((o3(ip,iw),iw=1,21), ip= 9, 9)/
     &  -0.2304E-10, -0.4564E-10, -0.8969E-10, -0.1735E-09, -0.3224E-09,
     &  -0.5933E-09, -0.9756E-09, -0.1428E-08, -0.1446E-08,  0.1156E-09,
     &   0.4499E-08,  0.8469E-08, -0.2720E-08, -0.4904E-07, -0.1401E-06,
     &  -0.2801E-06, -0.4681E-06, -0.6761E-06, -0.8387E-06, -0.8879E-06,
     &  -0.8040E-06/
      data ((o1(ip,iw),iw=1,21), ip=10,10)/
     &   0.99999344,  0.99998689,  0.99997360,  0.99994630,  0.99989259,
     &   0.99978650,  0.99957931,  0.99918163,  0.99843597,  0.99709100,
     &   0.99480897,  0.99122101,  0.98604000,  0.97902000,  0.96965003,
     &   0.95684999,  0.93896997,  0.91386002,  0.87910002,  0.83249998,
     &   0.77200001/
      data ((o2(ip,iw),iw=1,21), ip=10,10)/
     &  -0.2661E-09, -0.5923E-09, -0.1426E-08, -0.3816E-08, -0.1159E-07,
     &  -0.3654E-07, -0.1143E-06, -0.3559E-06, -0.1074E-05, -0.3083E-05,
     &  -0.8159E-05, -0.1932E-04, -0.3998E-04, -0.7253E-04, -0.1194E-03,
     &  -0.1845E-03, -0.2718E-03, -0.3833E-03, -0.5176E-03, -0.6701E-03,
     &  -0.8354E-03/
      data ((o3(ip,iw),iw=1,21), ip=10,10)/
     &  -0.2232E-10, -0.4421E-10, -0.8695E-10, -0.1684E-09, -0.3141E-09,
     &  -0.5765E-09, -0.9606E-09, -0.1434E-08, -0.1551E-08, -0.2663E-09,
     &   0.3515E-08,  0.6549E-08, -0.5479E-08, -0.5312E-07, -0.1460E-06,
     &  -0.2883E-06, -0.4787E-06, -0.6863E-06, -0.8399E-06, -0.8703E-06,
     &  -0.7602E-06/
      data ((o1(ip,iw),iw=1,21), ip=11,11)/
     &   0.99999356,  0.99998701,  0.99997360,  0.99994630,  0.99989289,
     &   0.99978679,  0.99957907,  0.99917960,  0.99843001,  0.99707502,
     &   0.99475998,  0.99109501,  0.98575002,  0.97843999,  0.96855003,
     &   0.95494002,  0.93572998,  0.90853000,  0.87070000,  0.81970000,
     &   0.75380003/
      data ((o2(ip,iw),iw=1,21), ip=11,11)/
     &  -0.4394E-09, -0.9330E-09, -0.2086E-08, -0.5054E-08, -0.1373E-07,
     &  -0.3971E-07, -0.1178E-06, -0.3546E-06, -0.1049E-05, -0.2976E-05,
     &  -0.7847E-05, -0.1860E-04, -0.3864E-04, -0.7038E-04, -0.1162E-03,
     &  -0.1798E-03, -0.2654E-03, -0.3754E-03, -0.5091E-03, -0.6621E-03,
     &  -0.8286E-03/
      data ((o3(ip,iw),iw=1,21), ip=11,11)/
     &  -0.2127E-10, -0.4216E-10, -0.8300E-10, -0.1611E-09, -0.3019E-09,
     &  -0.5597E-09, -0.9431E-09, -0.1450E-08, -0.1694E-08, -0.7913E-09,
     &   0.2144E-08,  0.3990E-08, -0.9282E-08, -0.5810E-07, -0.1525E-06,
     &  -0.2965E-06, -0.4869E-06, -0.6894E-06, -0.8281E-06, -0.8350E-06,
     &  -0.6956E-06/
      data ((o1(ip,iw),iw=1,21), ip=12,12)/
     &   0.99999368,  0.99998701,  0.99997377,  0.99994630,  0.99989259,
     &   0.99978709,  0.99957848,  0.99917740,  0.99842203,  0.99704897,
     &   0.99468797,  0.99090999,  0.98532999,  0.97758001,  0.96693999,
     &   0.95213997,  0.93109000,  0.90110999,  0.85930002,  0.80290002,
     &   0.73019999/
      data ((o2(ip,iw),iw=1,21), ip=12,12)/
     &  -0.6829E-09, -0.1412E-08, -0.3014E-08, -0.6799E-08, -0.1675E-07,
     &  -0.4450E-07, -0.1235E-06, -0.3538E-06, -0.1014E-05, -0.2827E-05,
     &  -0.7407E-05, -0.1759E-04, -0.3676E-04, -0.6744E-04, -0.1120E-03,
     &  -0.1742E-03, -0.2585E-03, -0.3683E-03, -0.5034E-03, -0.6594E-03,
     &  -0.8290E-03/
      data ((o3(ip,iw),iw=1,21), ip=12,12)/
     &  -0.1985E-10, -0.3937E-10, -0.7761E-10, -0.1511E-09, -0.2855E-09,
     &  -0.5313E-09, -0.9251E-09, -0.1470E-08, -0.1898E-08, -0.1519E-08,
     &   0.2914E-09,  0.5675E-09, -0.1405E-07, -0.6359E-07, -0.1584E-06,
     &  -0.3020E-06, -0.4893E-06, -0.6821E-06, -0.8021E-06, -0.7834E-06,
     &  -0.6105E-06/
      data ((o1(ip,iw),iw=1,21), ip=13,13)/
     &   0.99999368,  0.99998701,  0.99997389,  0.99994695,  0.99989289,
     &   0.99978721,  0.99957782,  0.99917412,  0.99840999,  0.99701297,
     &   0.99458599,  0.99064600,  0.98471999,  0.97632003,  0.96464998,
     &   0.94819999,  0.92467999,  0.89109999,  0.84430003,  0.78139997,
     &   0.70070004/
      data ((o2(ip,iw),iw=1,21), ip=13,13)/
     &  -0.1004E-08, -0.2043E-08, -0.4239E-08, -0.9104E-08, -0.2075E-07,
     &  -0.5096E-07, -0.1307E-06, -0.3520E-06, -0.9671E-06, -0.2630E-05,
     &  -0.6825E-05, -0.1624E-04, -0.3429E-04, -0.6369E-04, -0.1069E-03,
     &  -0.1680E-03, -0.2520E-03, -0.3635E-03, -0.5029E-03, -0.6647E-03,
     &  -0.8390E-03/
      data ((o3(ip,iw),iw=1,21), ip=13,13)/
     &  -0.1807E-10, -0.3587E-10, -0.7085E-10, -0.1385E-09, -0.2648E-09,
     &  -0.4958E-09, -0.8900E-09, -0.1473E-08, -0.2112E-08, -0.2399E-08,
     &  -0.2002E-08, -0.3646E-08, -0.1931E-07, -0.6852E-07, -0.1618E-06,
     &  -0.3021E-06, -0.4828E-06, -0.6634E-06, -0.7643E-06, -0.7177E-06,
     &  -0.5054E-06/
      data ((o1(ip,iw),iw=1,21), ip=14,14)/
     &   0.99999368,  0.99998713,  0.99997389,  0.99994725,  0.99989289,
     &   0.99978679,  0.99957597,  0.99916971,  0.99839503,  0.99696702,
     &   0.99444997,  0.99028301,  0.98387003,  0.97457999,  0.96148002,
     &   0.94284999,  0.91613001,  0.87809998,  0.82520002,  0.75489998,
     &   0.66520000/
      data ((o2(ip,iw),iw=1,21), ip=14,14)/
     &  -0.1387E-08, -0.2798E-08, -0.5706E-08, -0.1187E-07, -0.2564E-07,
     &  -0.5866E-07, -0.1398E-06, -0.3516E-06, -0.9148E-06, -0.2398E-05,
     &  -0.6122E-05, -0.1459E-04, -0.3125E-04, -0.5923E-04, -0.1013E-03,
     &  -0.1620E-03, -0.2473E-03, -0.3631E-03, -0.5098E-03, -0.6800E-03,
     &  -0.8603E-03/
      data ((o3(ip,iw),iw=1,21), ip=14,14)/
     &  -0.1610E-10, -0.3200E-10, -0.6337E-10, -0.1245E-09, -0.2408E-09,
     &  -0.4533E-09, -0.8405E-09, -0.1464E-08, -0.2337E-08, -0.3341E-08,
     &  -0.4467E-08, -0.8154E-08, -0.2436E-07, -0.7128E-07, -0.1604E-06,
     &  -0.2945E-06, -0.4666E-06, -0.6357E-06, -0.7187E-06, -0.6419E-06,
     &  -0.3795E-06/
      data ((o1(ip,iw),iw=1,21), ip=15,15)/
     &   0.99999410,  0.99998724,  0.99997455,  0.99994725,  0.99989331,
     &   0.99978632,  0.99957472,  0.99916393,  0.99837703,  0.99690801,
     &   0.99427801,  0.98982000,  0.98277998,  0.97232002,  0.95731997,
     &   0.93585998,  0.90521002,  0.86180001,  0.80190003,  0.72290003,
     &   0.62380004/
      data ((o2(ip,iw),iw=1,21), ip=15,15)/
     &  -0.1788E-08, -0.3588E-08, -0.7244E-08, -0.1479E-07, -0.3083E-07,
     &  -0.6671E-07, -0.1497E-06, -0.3519E-06, -0.8607E-06, -0.2154E-05,
     &  -0.5364E-05, -0.1276E-04, -0.2785E-04, -0.5435E-04, -0.9573E-04,
     &  -0.1570E-03, -0.2455E-03, -0.3682E-03, -0.5253E-03, -0.7065E-03,
     &  -0.8938E-03/
      data ((o3(ip,iw),iw=1,21), ip=15,15)/
     &  -0.1429E-10, -0.2843E-10, -0.5645E-10, -0.1115E-09, -0.2181E-09,
     &  -0.4200E-09, -0.7916E-09, -0.1460E-08, -0.2542E-08, -0.4168E-08,
     &  -0.6703E-08, -0.1215E-07, -0.2821E-07, -0.7073E-07, -0.1530E-06,
     &  -0.2791E-06, -0.4426E-06, -0.6027E-06, -0.6707E-06, -0.5591E-06,
     &  -0.2328E-06/
      data ((o1(ip,iw),iw=1,21), ip=16,16)/
     &   0.99999434,  0.99998778,  0.99997467,  0.99994761,  0.99989331,
     &   0.99978602,  0.99957269,  0.99915779,  0.99835497,  0.99684399,
     &   0.99408400,  0.98929000,  0.98148000,  0.96954000,  0.95212001,
     &   0.92719001,  0.89170003,  0.84200001,  0.77420002,  0.68620002,
     &   0.57780004/
      data ((o2(ip,iw),iw=1,21), ip=16,16)/
     &  -0.2141E-08, -0.4286E-08, -0.8603E-08, -0.1737E-07, -0.3548E-07,
     &  -0.7410E-07, -0.1590E-06, -0.3537E-06, -0.8142E-06, -0.1935E-05,
     &  -0.4658E-05, -0.1099E-04, -0.2444E-04, -0.4948E-04, -0.9067E-04,
     &  -0.1538E-03, -0.2474E-03, -0.3793E-03, -0.5495E-03, -0.7439E-03,
     &  -0.9383E-03/
      data ((o3(ip,iw),iw=1,21), ip=16,16)/
     &  -0.1295E-10, -0.2581E-10, -0.5136E-10, -0.1019E-09, -0.2011E-09,
     &  -0.3916E-09, -0.7585E-09, -0.1439E-08, -0.2648E-08, -0.4747E-08,
     &  -0.8301E-08, -0.1499E-07, -0.3024E-07, -0.6702E-07, -0.1399E-06,
     &  -0.2564E-06, -0.4117E-06, -0.5669E-06, -0.6239E-06, -0.4748E-06,
     &  -0.7013E-07/
      data ((o1(ip,iw),iw=1,21), ip=17,17)/
     &   0.99999434,  0.99998778,  0.99997479,  0.99994791,  0.99989331,
     &   0.99978608,  0.99957120,  0.99915212,  0.99833500,  0.99677801,
     &   0.99388403,  0.98873001,  0.98005998,  0.96639001,  0.94606000,
     &   0.91689998,  0.87580001,  0.81889999,  0.74280000,  0.64559996,
     &   0.52869999/
      data ((o2(ip,iw),iw=1,21), ip=17,17)/
     &  -0.2400E-08, -0.4796E-08, -0.9599E-08, -0.1927E-07, -0.3892E-07,
     &  -0.7954E-07, -0.1661E-06, -0.3540E-06, -0.7780E-06, -0.1763E-05,
     &  -0.4092E-05, -0.9512E-05, -0.2142E-04, -0.4502E-04, -0.8640E-04,
     &  -0.1525E-03, -0.2526E-03, -0.3955E-03, -0.5805E-03, -0.7897E-03,
     &  -0.9899E-03/
      data ((o3(ip,iw),iw=1,21), ip=17,17)/
     &  -0.1220E-10, -0.2432E-10, -0.4845E-10, -0.9640E-10, -0.1912E-09,
     &  -0.3771E-09, -0.7392E-09, -0.1420E-08, -0.2702E-08, -0.5049E-08,
     &  -0.9214E-08, -0.1659E-07, -0.3101E-07, -0.6162E-07, -0.1235E-06,
     &  -0.2287E-06, -0.3755E-06, -0.5274E-06, -0.5790E-06, -0.3947E-06,
     &   0.1003E-06/
      data ((o1(ip,iw),iw=1,21), ip=18,18)/
     &   0.99999464,  0.99998808,  0.99997497,  0.99994791,  0.99989331,
     &   0.99978518,  0.99957031,  0.99914658,  0.99831802,  0.99671799,
     &   0.99370098,  0.98821002,  0.97867000,  0.96313000,  0.93948001,
     &   0.90534002,  0.85769999,  0.79310000,  0.70840001,  0.60290003,
     &   0.47930002/
      data ((o2(ip,iw),iw=1,21), ip=18,18)/
     &  -0.2557E-08, -0.5106E-08, -0.1020E-07, -0.2043E-07, -0.4103E-07,
     &  -0.8293E-07, -0.1697E-06, -0.3531E-06, -0.7531E-06, -0.1645E-05,
     &  -0.3690E-05, -0.8411E-05, -0.1902E-04, -0.4118E-04, -0.8276E-04,
     &  -0.1525E-03, -0.2601E-03, -0.4147E-03, -0.6149E-03, -0.8384E-03,
     &  -0.1042E-02/
      data ((o3(ip,iw),iw=1,21), ip=18,18)/
     &  -0.1189E-10, -0.2372E-10, -0.4729E-10, -0.9421E-10, -0.1873E-09,
     &  -0.3713E-09, -0.7317E-09, -0.1437E-08, -0.2764E-08, -0.5243E-08,
     &  -0.9691E-08, -0.1751E-07, -0.3122E-07, -0.5693E-07, -0.1076E-06,
     &  -0.1981E-06, -0.3324E-06, -0.4785E-06, -0.5280E-06, -0.3174E-06,
     &   0.2672E-06/
      data ((o1(ip,iw),iw=1,21), ip=19,19)/
     &   0.99999464,  0.99998820,  0.99997509,  0.99994779,  0.99989331,
     &   0.99978518,  0.99956989,  0.99914283,  0.99830401,  0.99667197,
     &   0.99355298,  0.98776001,  0.97741997,  0.96007001,  0.93285000,
     &   0.89310002,  0.83819997,  0.76520002,  0.67250001,  0.56000000,
     &   0.43199998/
      data ((o2(ip,iw),iw=1,21), ip=19,19)/
     &  -0.2630E-08, -0.5249E-08, -0.1048E-07, -0.2096E-07, -0.4198E-07,
     &  -0.8440E-07, -0.1710E-06, -0.3513E-06, -0.7326E-06, -0.1562E-05,
     &  -0.3416E-05, -0.7637E-05, -0.1719E-04, -0.3795E-04, -0.7926E-04,
     &  -0.1524E-03, -0.2680E-03, -0.4344E-03, -0.6486E-03, -0.8838E-03,
     &  -0.1089E-02/
      data ((o3(ip,iw),iw=1,21), ip=19,19)/
     &  -0.1188E-10, -0.2369E-10, -0.4725E-10, -0.9417E-10, -0.1875E-09,
     &  -0.3725E-09, -0.7365E-09, -0.1445E-08, -0.2814E-08, -0.5384E-08,
     &  -0.1008E-07, -0.1816E-07, -0.3179E-07, -0.5453E-07, -0.9500E-07,
     &  -0.1679E-06, -0.2819E-06, -0.4109E-06, -0.4555E-06, -0.2283E-06,
     &   0.4283E-06/
      data ((o1(ip,iw),iw=1,21), ip=20,20)/
     &   0.99999487,  0.99998832,  0.99997520,  0.99994791,  0.99989331,
     &   0.99978459,  0.99956900,  0.99913990,  0.99829400,  0.99663699,
     &   0.99344099,  0.98741001,  0.97643000,  0.95743001,  0.92672002,
     &   0.88099998,  0.81809998,  0.73660004,  0.63620001,  0.51880002,
     &   0.38880002/
      data ((o2(ip,iw),iw=1,21), ip=20,20)/
     &  -0.2651E-08, -0.5291E-08, -0.1056E-07, -0.2110E-07, -0.4221E-07,
     &  -0.8462E-07, -0.1705E-06, -0.3466E-06, -0.7155E-06, -0.1501E-05,
     &  -0.3223E-05, -0.7079E-05, -0.1581E-04, -0.3517E-04, -0.7553E-04,
     &  -0.1510E-03, -0.2746E-03, -0.4528E-03, -0.6789E-03, -0.9214E-03,
     &  -0.1124E-02/
      data ((o3(ip,iw),iw=1,21), ip=20,20)/
     &  -0.1193E-10, -0.2380E-10, -0.4748E-10, -0.9465E-10, -0.1886E-09,
     &  -0.3751E-09, -0.7436E-09, -0.1466E-08, -0.2872E-08, -0.5508E-08,
     &  -0.1038E-07, -0.1891E-07, -0.3279E-07, -0.5420E-07, -0.8711E-07,
     &  -0.1403E-06, -0.2248E-06, -0.3221E-06, -0.3459E-06, -0.1066E-06,
     &   0.5938E-06/
      data ((o1(ip,iw),iw=1,21), ip=21,21)/
     &   0.99999487,  0.99998873,  0.99997509,  0.99994779,  0.99989349,
     &   0.99978501,  0.99956918,  0.99913877,  0.99828798,  0.99661303,
     &   0.99335998,  0.98715001,  0.97566003,  0.95530999,  0.92153001,
     &   0.87000000,  0.79869998,  0.70819998,  0.60109997,  0.48110002,
     &   0.35140002/
      data ((o2(ip,iw),iw=1,21), ip=21,21)/
     &  -0.2654E-08, -0.5296E-08, -0.1057E-07, -0.2111E-07, -0.4219E-07,
     &  -0.8445E-07, -0.1696E-06, -0.3428E-06, -0.7013E-06, -0.1458E-05,
     &  -0.3084E-05, -0.6678E-05, -0.1476E-04, -0.3284E-04, -0.7173E-04,
     &  -0.1481E-03, -0.2786E-03, -0.4688E-03, -0.7052E-03, -0.9506E-03,
     &  -0.1148E-02/
      data ((o3(ip,iw),iw=1,21), ip=21,21)/
     &  -0.1195E-10, -0.2384E-10, -0.4755E-10, -0.9482E-10, -0.1890E-09,
     &  -0.3761E-09, -0.7469E-09, -0.1476E-08, -0.2892E-08, -0.5603E-08,
     &  -0.1060E-07, -0.1942E-07, -0.3393E-07, -0.5508E-07, -0.8290E-07,
     &  -0.1182E-06, -0.1657E-06, -0.2170E-06, -0.1997E-06,  0.6227E-07,
     &   0.7847E-06/
      data ((o1(ip,iw),iw=1,21), ip=22,22)/
     &   0.99999541,  0.99998873,  0.99997497,  0.99994737,  0.99989349,
     &   0.99978501,  0.99956882,  0.99913770,  0.99828303,  0.99659699,
     &   0.99330199,  0.98697001,  0.97510999,  0.95372999,  0.91742998,
     &   0.86080003,  0.78139997,  0.68220001,  0.56920004,  0.44809997,
     &   0.32080001/
      data ((o2(ip,iw),iw=1,21), ip=22,22)/
     &  -0.2653E-08, -0.5295E-08, -0.1057E-07, -0.2110E-07, -0.4215E-07,
     &  -0.8430E-07, -0.1690E-06, -0.3403E-06, -0.6919E-06, -0.1427E-05,
     &  -0.2991E-05, -0.6399E-05, -0.1398E-04, -0.3099E-04, -0.6824E-04,
     &  -0.1441E-03, -0.2795E-03, -0.4814E-03, -0.7282E-03, -0.9739E-03,
     &  -0.1163E-02/
      data ((o3(ip,iw),iw=1,21), ip=22,22)/
     &  -0.1195E-10, -0.2384E-10, -0.4756E-10, -0.9485E-10, -0.1891E-09,
     &  -0.3765E-09, -0.7483E-09, -0.1481E-08, -0.2908E-08, -0.5660E-08,
     &  -0.1075E-07, -0.1980E-07, -0.3472E-07, -0.5626E-07, -0.8149E-07,
     &  -0.1027E-06, -0.1136E-06, -0.1071E-06, -0.2991E-07,  0.2743E-06,
     &   0.1017E-05/
      data ((o1(ip,iw),iw=1,21), ip=23,23)/
     &   0.99999595,  0.99998885,  0.99997479,  0.99994725,  0.99989331,
     &   0.99978518,  0.99956882,  0.99913692,  0.99827999,  0.99658602,
     &   0.99326497,  0.98685002,  0.97474003,  0.95260000,  0.91441000,
     &   0.85360003,  0.76719999,  0.65990001,  0.54190004,  0.42119998,
     &   0.29699999/
      data ((o2(ip,iw),iw=1,21), ip=23,23)/
     &  -0.2653E-08, -0.5294E-08, -0.1057E-07, -0.2109E-07, -0.4212E-07,
     &  -0.8420E-07, -0.1686E-06, -0.3388E-06, -0.6858E-06, -0.1406E-05,
     &  -0.2928E-05, -0.6206E-05, -0.1344E-04, -0.2961E-04, -0.6533E-04,
     &  -0.1399E-03, -0.2780E-03, -0.4904E-03, -0.7488E-03, -0.9953E-03,
     &  -0.1175E-02/
      data ((o3(ip,iw),iw=1,21), ip=23,23)/
     &  -0.1195E-10, -0.2384E-10, -0.4756E-10, -0.9485E-10, -0.1891E-09,
     &  -0.3767E-09, -0.7492E-09, -0.1485E-08, -0.2924E-08, -0.5671E-08,
     &  -0.1084E-07, -0.2009E-07, -0.3549E-07, -0.5773E-07, -0.8208E-07,
     &  -0.9394E-07, -0.7270E-07, -0.3947E-08,  0.1456E-06,  0.5083E-06,
     &   0.1270E-05/
      data ((o1(ip,iw),iw=1,21), ip=24,24)/
     &   0.99999630,  0.99998873,  0.99997401,  0.99994725,  0.99989349,
     &   0.99978501,  0.99956959,  0.99913663,  0.99827701,  0.99658000,
     &   0.99324101,  0.98676997,  0.97447002,  0.95185000,  0.91232002,
     &   0.84850001,  0.75660002,  0.64230001,  0.52030003,  0.40090001,
     &   0.27980000/
      data ((o2(ip,iw),iw=1,21), ip=24,24)/
     &  -0.2653E-08, -0.5294E-08, -0.1056E-07, -0.2109E-07, -0.4210E-07,
     &  -0.8413E-07, -0.1684E-06, -0.3379E-06, -0.6820E-06, -0.1393E-05,
     &  -0.2889E-05, -0.6080E-05, -0.1307E-04, -0.2861E-04, -0.6310E-04,
     &  -0.1363E-03, -0.2758E-03, -0.4969E-03, -0.7681E-03, -0.1017E-02,
     &  -0.1186E-02/
      data ((o3(ip,iw),iw=1,21), ip=24,24)/
     &  -0.1195E-10, -0.2384E-10, -0.4756E-10, -0.9485E-10, -0.1891E-09,
     &  -0.3768E-09, -0.7497E-09, -0.1487E-08, -0.2933E-08, -0.5710E-08,
     &  -0.1089E-07, -0.2037E-07, -0.3616E-07, -0.5907E-07, -0.8351E-07,
     &  -0.8925E-07, -0.4122E-07,  0.8779E-07,  0.3143E-06,  0.7281E-06,
     &   0.1500E-05/
      data ((o1(ip,iw),iw=1,21), ip=25,25)/
     &   0.99999648,  0.99998897,  0.99997377,  0.99994749,  0.99989331,
     &   0.99978501,  0.99956989,  0.99913692,  0.99827600,  0.99657297,
     &   0.99322498,  0.98672003,  0.97431999,  0.95137000,  0.91095001,
     &   0.84500003,  0.74909997,  0.62979996,  0.50510001,  0.38679999,
     &   0.26789999/
      data ((o2(ip,iw),iw=1,21), ip=25,25)/
     &  -0.2653E-08, -0.5293E-08, -0.1056E-07, -0.2108E-07, -0.4209E-07,
     &  -0.8409E-07, -0.1682E-06, -0.3373E-06, -0.6797E-06, -0.1383E-05,
     &  -0.2862E-05, -0.5993E-05, -0.1283E-04, -0.2795E-04, -0.6158E-04,
     &  -0.1338E-03, -0.2743E-03, -0.5030E-03, -0.7863E-03, -0.1038E-02,
     &  -0.1196E-02/
      data ((o3(ip,iw),iw=1,21), ip=25,25)/
     &  -0.1195E-10, -0.2383E-10, -0.4755E-10, -0.9484E-10, -0.1891E-09,
     &  -0.3768E-09, -0.7499E-09, -0.1489E-08, -0.2939E-08, -0.5741E-08,
     &  -0.1100E-07, -0.2066E-07, -0.3660E-07, -0.6002E-07, -0.8431E-07,
     &  -0.8556E-07, -0.1674E-07,  0.1638E-06,  0.4525E-06,  0.8949E-06,
     &   0.1669E-05/
      data ((o1(ip,iw),iw=1,21), ip=26,26)/
     &   0.99999672,  0.99998909,  0.99997377,  0.99994695,  0.99989349,
     &   0.99978518,  0.99956989,  0.99913692,  0.99827498,  0.99657100,
     &   0.99321902,  0.98668998,  0.97421002,  0.95106000,  0.91009998,
     &   0.84280002,  0.74430001,  0.62180001,  0.49519998,  0.37800002,
     &   0.25999999/
      data ((o2(ip,iw),iw=1,21), ip=26,26)/
     &  -0.2652E-08, -0.5292E-08, -0.1056E-07, -0.2108E-07, -0.4208E-07,
     &  -0.8406E-07, -0.1681E-06, -0.3369E-06, -0.6784E-06, -0.1378E-05,
     &  -0.2843E-05, -0.5944E-05, -0.1269E-04, -0.2759E-04, -0.6078E-04,
     &  -0.1326E-03, -0.2742E-03, -0.5088E-03, -0.8013E-03, -0.1054E-02,
     &  -0.1202E-02/
      data ((o3(ip,iw),iw=1,21), ip=26,26)/
     &  -0.1194E-10, -0.2383E-10, -0.4754E-10, -0.9482E-10, -0.1891E-09,
     &  -0.3768E-09, -0.7499E-09, -0.1489E-08, -0.2941E-08, -0.5752E-08,
     &  -0.1104E-07, -0.2069E-07, -0.3661E-07, -0.6012E-07, -0.8399E-07,
     &  -0.8183E-07,  0.1930E-08,  0.2167E-06,  0.5434E-06,  0.9990E-06,
     &   0.1787E-05/
cxp
      np1 = np + 1
      allocate(acflxu(nx1,np1))
      allocate(acflxd(nx1,np1))
      allocate(pa(m,np))
      allocate(dt(m,np))
      allocate(sh2o(m,np+1))
      allocate(swpre(m,np+1))
      allocate(swtem(m,np+1))
      allocate(sco3(m,np+1))
      allocate(scopre(m,np+1))
      allocate(scotem(m,np+1))
      allocate(dh2o(m,np))
      allocate(dcont(m,np))
      allocate(dco2(m,np))
      allocate(do3(m,np))
      allocate(dn2o(m,np))
      allocate(dch4(m,np))
      allocate(df11(m,np))
      allocate(df12(m,np))
      allocate(df22(m,np))
      allocate(th2o(m,6))
      allocate(tcon(m,3))
      allocate(tco2(m,6,2))
      allocate(tn2o(m,4))
      allocate(tch4(m,4))
      allocate(tcom(m,6))
      allocate(tf11(m))
      allocate(tf12(m))
      allocate(tf22(m))
      allocate(h2oexp(m,np,6))
      allocate(conexp(m,np,3))
      allocate(co2exp(m,np,6,2))
      allocate(n2oexp(m,np,4))
      allocate(ch4exp(m,np,4))
      allocate(comexp(m,np,6))
      allocate(f11exp(m,np))
      allocate(f12exp(m,np))
      allocate(f22exp(m,np))
      allocate(blayer(m,0:np+1))
      allocate(blevel(m,np+1))
      allocate(dblayr(m,np+1))
      allocate(dbs(m))
      allocate(dp(m,np))
      allocate(cwp(m,np,3))
      allocate(trant(m))
      allocate(tranal(m))
      allocate(transfc(m,np+1))
      allocate(trantcr(m,np+1))
      allocate(flxu(m,np+1))
      allocate(flxd(m,np+1))
      allocate(flcu(m,np+1))
      allocate(flcd(m,np+1))
      allocate(rflx(m,np+1))
      allocate(rflc(m,np+1))
      allocate(it(m))
      allocate(im(m))
      allocate(ib(m))
      allocate(cldhi(m))
      allocate(cldmd(m))
      allocate(cldlw(m))
      allocate(tcldlyr(m,np))
      allocate(fclr(m))
      allocate(taerlyr(m,np))
c-----compute layer pressure (pa) and layer temperature minus 250k (dt)
       do j=1,10
       do k=1,np
       do i=1,m
          taual(i,k,j)=0.
          ssaal(i,k,j)=0.
          asyal(i,k,j)=0.
       enddo
       enddo
       enddo
      do k=1,np
       do i=1,m
         pa(i,k)=0.5*(pl(i,k)+pl(i,k+1))
         dt(i,k)=ta(i,k)-250.0
       enddo
      enddo
c-----compute layer absorber amount
c     dh2o : water vapor amount (g/cm**2)
c     dcont: scaled water vapor amount for continuum absorption
c            (g/cm**2)
c     dco2 : co2 amount (cm-atm)stp
c     do3  : o3 amount (cm-atm)stp
c     dn2o : n2o amount (cm-atm)stp
c     dch4 : ch4 amount (cm-atm)stp
c     df11 : cfc11 amount (cm-atm)stp
c     df12 : cfc12 amount (cm-atm)stp
c     df22 : cfc22 amount (cm-atm)stp
c     the factor 1.02 is equal to 1000/980
c     factors 789 and 476 are for unit conversion
c     the factor 0.001618 is equal to 1.02/(.622*1013.25) 
c     the factor 6.081 is equal to 1800/296
      do k=1,np
       do i=1,m
         dp   (i,k) = pl(i,k+1)-pl(i,k)
         dh2o (i,k) = 1.02*wa(i,k)*dp(i,k)+1.e-10
         do3  (i,k) = 476.*oa(i,k)*dp(i,k)+1.e-10
         dco2 (i,k) = 789.*co2*dp(i,k)+1.e-10
         dch4 (i,k) = 789.*ch4*dp(i,k)+1.e-10
         dn2o (i,k) = 789.*n2o*dp(i,k)+1.e-10
         df11 (i,k) = 789.*cfc11*dp(i,k)+1.e-10
         df12 (i,k) = 789.*cfc12*dp(i,k)+1.e-10
         df22 (i,k) = 789.*cfc22*dp(i,k)+1.e-10
c-----compute scaled water vapor amount for h2o continuum absorption
c     following eq. (4.21).
         xx=pa(i,k)*0.001618*wa(i,k)*wa(i,k)*dp(i,k)
         dcont(i,k) = xx*exp(1800./ta(i,k)-6.081)+1.e-10
       enddo
      enddo
c-----compute column-integrated h2o amoumt (sh2o), h2o-weighted pressure
c     (swpre) and temperature (swtem). it follows eqs. (4.13) and (4.14).
       if (high) then
        call column(m,np,pa,dt,dh2o,sh2o,swpre,swtem)
       endif
c-----compute layer cloud water amount (gm/m**2)
c     index is 1 for ice, 2 for waterdrops and 3 for raindrops.
       if (cldwater) then
        do k=1,np
         do i=1,m
             xx=1.02*10000.*(pl(i,k+1)-pl(i,k))
             cwp(i,k,1)=xx*cwc(i,k,1)
             cwp(i,k,2)=xx*cwc(i,k,2)
             cwp(i,k,3)=xx*cwc(i,k,3)
         enddo
        enddo
       endif
c-----the surface (np+1) is treated as a layer filled with black clouds.
c     transfc is the transmttance between the surface and a pressure level.
c     trantcr is the clear-sky transmttance between the surface and a
c     pressure level.
      do i=1,m
        sfcem(i)       =0.0
        transfc(i,np+1)=1.0
        trantcr(i,np+1)=1.0
      enddo
c-----initialize fluxes
      do k=1,np+1
       do i=1,m
         flx(i,k)  = 0.0
         flc(i,k)  = 0.0
         dfdts(i,k)= 0.0
         rflx(i,k) = 0.0
         rflc(i,k) = 0.0
cccshie 8/13/04 based on M Yan
         acflxu(i,k) = 0.0
         acflxd(i,k) = 0.0
       enddo
      enddo
c-----integration over spectral bands
      do 1000 ibn=1,10
c-----if h2otbl, compute h2o (line) transmittance using table look-up.
c     if conbnd, compute h2o (continuum) transmittance in bands 3-7.
c     if co2bnd, compute co2 transmittance in band 3.
c     if oznbnd, compute  o3 transmittance in band 5.
c     if n2obnd, compute n2o transmittance in bands 6 and 7.
c     if ch4bnd, compute ch4 transmittance in bands 6 and 7.
c     if combnd, compute co2-minor transmittance in bands 4 and 5.
c     if f11bnd, compute cfc11 transmittance in bands 4 and 5.
c     if f12bnd, compute cfc12 transmittance in bands 4 and 6.
c     if f22bnd, compute cfc22 transmittance in bands 4 and 6.
c     if b10bnd, compute flux reduction due to n2o in band 10.
       h2otbl=high.and.(ibn.eq.1.or.ibn.eq.2.or.ibn.eq.8)
       conbnd=ibn.ge.3.and.ibn.le.7
       co2bnd=ibn.eq.3
       oznbnd=ibn.eq.5
       n2obnd=ibn.eq.6.or.ibn.eq.7
       ch4bnd=ibn.eq.6.or.ibn.eq.7
       combnd=ibn.eq.4.or.ibn.eq.5
       f11bnd=ibn.eq.4.or.ibn.eq.5
       f12bnd=ibn.eq.4.or.ibn.eq.6
       f22bnd=ibn.eq.4.or.ibn.eq.6
       b10bnd=ibn.eq.10
       if (.not. b10bnd .or. trace) then          ! skip b10 and .not.trace
c-----blayer is the spectrally integrated planck flux of the mean layer
c     temperature derived from eq. (3.11)
c     the fitting for the planck flux is valid for the range 160-345 k.
       do k=1,np
        do i=1,m
          blayer(i,k)=ta(i,k)*(ta(i,k)*(ta(i,k)*(ta(i,k)
     *               *(ta(i,k)*cb(6,ibn)+cb(5,ibn))+cb(4,ibn))
     *               +cb(3,ibn))+cb(2,ibn))+cb(1,ibn)
        enddo
       enddo
       do i=1,m
c-----the earth's surface, with index "np+1", is treated as a layer.
c     index "0" is the layer above the top of the atmosphere.
         blayer(i,np+1)=(ts(i)*(ts(i)*(ts(i)*(ts(i)
     *                 *(ts(i)*cb(6,ibn)+cb(5,ibn))+cb(4,ibn))
     *                 +cb(3,ibn))+cb(2,ibn))+cb(1,ibn))*emiss(i,ibn)
         blayer(i,0)   = 0.0
c-----dbs is the derivative of the surface emission with respect to
c     surface temperature eq. (3.12).
        dbs(i)=(ts(i)*(ts(i)*(ts(i)*(ts(i)*5.*cb(6,ibn)+4.*cb(5,ibn))
     *        +3.*cb(4,ibn))+2.*cb(3,ibn))+cb(2,ibn))*emiss(i,ibn)
       enddo
c-----difference in planck functions between adjacent layers.
       do k=1,np+1
        do i=1,m
         dblayr(i,k)=blayer(i,k-1)-blayer(i,k)
        enddo
       enddo
c------interpolate planck function at model levels
       do k=2,np
        do i=1,m
         blevel(i,k)=(blayer(i,k-1)*dp(i,k)+blayer(i,k)*dp(i,k-1))/
     *               (dp(i,k-1)+dp(i,k))
        enddo
       enddo
       do i=1,m
         blevel(i,1)=blayer(i,1)+(blayer(i,1)-blayer(i,2))*dp(i,1)/
     *               (dp(i,1)+dp(i,2))
         blevel(i,np+1)=tb(i)*(tb(i)*(tb(i)*(tb(i)
     *                 *(tb(i)*cb(6,ibn)+cb(5,ibn))+cb(4,ibn))
     *                 +cb(3,ibn))+cb(2,ibn))+cb(1,ibn)
       enddo
c-----compute column-integrated absorber amoumt, absorber-weighted
c     pressure and temperature for co2 (band 3) and o3 (band 5).
c     it follows eqs. (4.13) and (4.14).
c-----this is in the band loop to save storage
      if (high .and. co2bnd) then
        call column(m,np,pa,dt,dco2,sco3,scopre,scotem)
      endif
      if (oznbnd) then
        call column(m,np,pa,dt,do3,sco3,scopre,scotem)
      endif
c-----compute cloud optical thickness following eqs. (6.4a,b) and (6.7)
c     rain optical thickness is set to 0.00307 /(gm/m**2).
c     it is for a specific drop size distribution provided by q. fu.
      if (cldwater) then
       do k=1,np
        do i=1,m
          taucl(i,k,1)=cwp(i,k,1)*(aib(1,ibn)+aib(2,ibn)/
     *      reff(i,k,1)**aib(3,ibn))
          taucl(i,k,2)=cwp(i,k,2)*(awb(1,ibn)+(awb(2,ibn)+
     *      (awb(3,ibn)+awb(4,ibn)*reff(i,k,2))*reff(i,k,2))
     *      *reff(i,k,2))
          taucl(i,k,3)=0.00307*cwp(i,k,3)
        enddo
       enddo
      endif
c-----compute cloud single-scattering albedo and asymmetry factor for
c     a mixture of ice particles and liquid drops following 
c     eqs. (6.5), (6.6), (6.11) and (6.12).
c     single-scattering albedo and asymmetry factor of rain are set
c     to 0.54 and 0.95, respectively, based on the information provided
c     by prof. qiang fu.
       do k=1,np
        do i=1,m
           tcldlyr(i,k) = 1.0
           taux=taucl(i,k,1)+taucl(i,k,2)+taucl(i,k,3)
          if (taux.gt.0.02 .and. fcld(i,k).gt.0.01) then
            reff1=min(reff(i,k,1),150.)
            reff2=min(reff(i,k,2),20.0)
           w1=taucl(i,k,1)*(aiw(1,ibn)+(aiw(2,ibn)+(aiw(3,ibn)
     *       +aiw(4,ibn)*reff1)*reff1)*reff1)
           w2=taucl(i,k,2)*(aww(1,ibn)+(aww(2,ibn)+(aww(3,ibn)
     *       +aww(4,ibn)*reff2)*reff2)*reff2)
           w3=taucl(i,k,3)*0.54
           ww=(w1+w2+w3)/taux
           g1=w1*(aig(1,ibn)+(aig(2,ibn)+(aig(3,ibn)
     *      +aig(4,ibn)*reff1)*reff1)*reff1)
           g2=w2*(awg(1,ibn)+(awg(2,ibn)+(awg(3,ibn)
     *      +awg(4,ibn)*reff2)*reff2)*reff2)
           g3=w3*0.95
           gg=(g1+g2+g3)/(w1+w2+w3)
c-----parameterization of lw scattering following eqs. (6.8) and (6.9). 
           ff=0.5+(0.3739+(0.0076+0.1185*gg)*gg)*gg
           taux=taux*(1.-ww*ff)
c-----compute cloud diffuse transmittance. it is approximated by using 
c     a diffusivity factor of 1.66.
           tauxa=max(0.,1.66*taux)
           tcldlyr(i,k)=0.
           if(tauxa.lt.80.)tcldlyr(i,k)=exp(-tauxa)
          endif
        enddo
       enddo
c-----for aerosol diffuse transmittance
c     the same scaling of cloud optical thickness is applied to aerosols
       do k=1,np
        do i=1,m
           taerlyr(i,k)=1.0
          if (taual(i,k,ibn).gt.0.01) then
           ff=0.5+(0.3739+(0.0076+0.1185*asyal(i,k,ibn))
     *      *asyal(i,k,ibn))*asyal(i,k,ibn)
           taux=taual(i,k,ibn)*(1.-ssaal(i,k,ibn)*ff)
           taerlyr(i,k)=exp(-1.66*taux)
          endif
        enddo
       enddo
c-----compute the exponential terms (eq. 8.18) at each layer due to
c     water vapor line absorption when k-distribution is used
      if (.not.h2otbl .and. .not.b10bnd) then
        call h2oexps(ibn,m,np,dh2o,pa,dt,xkw,aw,bw,pm,mw,h2oexp)
      endif
c-----compute the exponential terms (eq. 8.18) at each layer due to
c     water vapor continuum absorption
      if (conbnd) then
        call conexps(ibn,m,np,dcont,xke,conexp)
      endif
c-----compute the exponential terms (eq. 8.18) at each layer due to
c     co2 absorption
      if (.not.high .and. co2bnd) then
        call co2exps(m,np,dco2,pa,dt,co2exp)
      endif
c***** for trace gases *****
      if (trace) then
c-----compute the exponential terms at each layer due to n2o absorption
       if (n2obnd) then
        call n2oexps(ibn,m,np,dn2o,pa,dt,n2oexp)
       endif
c-----compute the exponential terms at each layer due to ch4 absorption
       if (ch4bnd) then
        call ch4exps(ibn,m,np,dch4,pa,dt,ch4exp)
       endif
c-----compute the exponential terms due to co2 minor absorption
       if (combnd) then
        call comexps(ibn,m,np,dco2,dt,comexp)
       endif
c-----compute the exponential terms due to cfc11 absorption.
c     the values of the parameters are given in table 7.
       if (f11bnd) then
            a1  = 1.26610e-3
            b1  = 3.55940e-6
            fk1 = 1.89736e+1
            a2  = 8.19370e-4
            b2  = 4.67810e-6
            fk2 = 1.01487e+1
        call cfcexps(ibn,m,np,a1,b1,fk1,a2,b2,fk2,df11,dt,f11exp)
       endif
c-----compute the exponential terms due to cfc12 absorption.
       if (f12bnd) then
            a1  = 8.77370e-4
            b1  =-5.88440e-6
            fk1 = 1.58104e+1
            a2  = 8.62000e-4
            b2  =-4.22500e-6
            fk2 = 3.70107e+1
        call cfcexps(ibn,m,np,a1,b1,fk1,a2,b2,fk2,df12,dt,f12exp)
       endif
c-----compute the exponential terms due to cfc22 absorption.
       if (f22bnd) then
            a1  = 9.65130e-4
            b1  = 1.31280e-5
            fk1 = 6.18536e+0
            a2  =-3.00010e-5 
            b2  = 5.25010e-7
            fk2 = 3.27912e+1
        call cfcexps(ibn,m,np,a1,b1,fk1,a2,b2,fk2,df22,dt,f22exp)
       endif
c-----compute the exponential terms at each layer in band 10 due to
c     h2o line and continuum, co2, and n2o absorption
       if (b10bnd) then
        call b10exps(m,np,dh2o,dcont,dco2,dn2o,pa,dt
     *              ,h2oexp,conexp,co2exp,n2oexp)
       endif
      endif
c-----compute transmittances for regions between levels k1 and k2
c     and update fluxes at the two levels.
c-----initialize fluxes
      do k=1,np+1
       do i=1,m
         flxu(i,k) = 0.0
         flxd(i,k) = 0.0
         flcu(i,k) = 0.0
         flcd(i,k) = 0.0
       enddo
      enddo
      do 2000 k1=1,np
c-----initialization
c
c     it, im, and ib are the numbers of cloudy layers in the high,
c     middle, and low cloud groups between levels k1 and k2.
c     cldlw, cldmd, and cldhi are the equivalent black-cloud fractions
c     of low, middle, and high troposphere.
c     tranal is the aerosol transmission function
        do i=1,m
          it(i) = 0
          im(i) = 0
          ib(i) = 0
          cldlw(i) = 0.0
          cldmd(i) = 0.0
          cldhi(i) = 0.0
          tranal(i)= 1.0
        enddo
c-----for h2o line transmission
      if (.not. h2otbl) then
        do ik=1,6
         do i=1,m
           th2o(i,ik)=1.0
         enddo
        enddo
      endif
c-----for h2o continuum transmission
         do iq=1,3
          do i=1,m
            tcon(i,iq)=1.0
          enddo
         enddo
c-----for co2 transmission using k-distribution method.
c     band 3 is divided into 3 sub-bands, but sub-bands 3a and 3c
c     are combined in computing the co2 transmittance.
       if (.not.high .and. co2bnd) then
         do isb=1,2
          do ik=1,6
           do i=1,m
             tco2(i,ik,isb)=1.0
           enddo
          enddo
         enddo
       endif
c***** for trace gases *****
      if (trace) then
c-----for n2o transmission using k-distribution method.
       if (n2obnd) then
          do ik=1,4
           do i=1,m
             tn2o(i,ik)=1.0
           enddo
          enddo
       endif
c-----for ch4 transmission using k-distribution method.
       if (ch4bnd) then
          do ik=1,4
           do i=1,m
             tch4(i,ik)=1.0
           enddo
          enddo
       endif
c-----for co2-minor transmission using k-distribution method.
       if (combnd) then
          do ik=1,6
           do i=1,m
             tcom(i,ik)=1.0
           enddo
          enddo
       endif
c-----for cfc-11 transmission using k-distribution method.
       if (f11bnd) then
           do i=1,m
             tf11(i)=1.0
           enddo
       endif
c-----for cfc-12 transmission using k-distribution method.
       if (f12bnd) then
           do i=1,m
             tf12(i)=1.0
           enddo
       endif
c-----for cfc-22 transmission when using k-distribution method.
       if (f22bnd) then
           do i=1,m
             tf22(i)=1.0
           enddo
       endif
c-----for the transmission in band 10 using k-distribution method.
       if (b10bnd) then
          do ik=1,5
           do i=1,m
              th2o(i,ik)=1.0
           enddo
          enddo
          do ik=1,6
           do i=1,m
              tco2(i,ik,1)=1.0
           enddo
          enddo
          do i=1,m
             tcon(i,1)=1.0
          enddo
          do ik=1,2
            do i=1,m
              tn2o(i,ik)=1.0
           enddo
          enddo
       endif
      endif
c***** end trace gases *****
       do i=1,m
        fclr(i)=1.0
       enddo
c-----loop over the bottom level of the region (k2)
      do 3000 k2=k1+1,np+1
c-----trant is the total transmittance between levels k1 and k2.
          do i=1,m
           trant(i)=1.0
          enddo
      if (h2otbl) then
c-----compute water vapor transmittance using table look-up.
c     the following values are taken from table 8.
          w1=-8.0
          p1=-2.0
          dwe=0.3
          dpe=0.2
          if (ibn.eq.1) then
           call tablup(k1,k2,m,np,nx2,nh,sh2o,swpre,swtem,
     *                 w1,p1,dwe,dpe,h11,h12,h13,trant)
          endif
          if (ibn.eq.2) then
           call tablup(k1,k2,m,np,nx2,nh,sh2o,swpre,swtem,
     *                 w1,p1,dwe,dpe,h21,h22,h23,trant)
          endif
          if (ibn.eq.8) then
           call tablup(k1,k2,m,np,nx2,nh,sh2o,swpre,swtem,
     *                 w1,p1,dwe,dpe,h81,h82,h83,trant)
          endif
      else
c-----compute water vapor transmittance using k-distribution
       if (.not.b10bnd) then
        call h2okdis(ibn,m,np,k2-1,fkw,gkw,ne,h2oexp,conexp,
     *               th2o,tcon,trant)
       endif
      endif
      if (co2bnd) then
        if (high) then
c-----compute co2 transmittance using table look-up method.
c     the following values are taken from table 8.
          w1=-4.0
          p1=-2.0
          dwe=0.3
          dpe=0.2
          call tablup(k1,k2,m,np,nx2,nc,sco3,scopre,scotem,
     *                w1,p1,dwe,dpe,c1,c2,c3,trant)
       else
c-----compute co2 transmittance using k-distribution method
          call co2kdis(m,np,k2-1,co2exp,tco2,trant)
        endif
      endif
c-----always use table look-up to compute o3 transmittance.
c     the following values are taken from table 8.
      if (oznbnd) then
          w1=-6.0
          p1=-2.0
          dwe=0.3
          dpe=0.2
          call tablup(k1,k2,m,np,nx2,no,sco3,scopre,scotem,
     *                w1,p1,dwe,dpe,o1,o2,o3,trant)
      endif
c***** for trace gases *****
      if (trace) then
c-----compute n2o transmittance using k-distribution method
       if (n2obnd) then
          call n2okdis(ibn,m,np,k2-1,n2oexp,tn2o,trant)
       endif
c-----compute ch4 transmittance using k-distribution method
       if (ch4bnd) then
          call ch4kdis(ibn,m,np,k2-1,ch4exp,tch4,trant)
       endif
c-----compute co2-minor transmittance using k-distribution method
       if (combnd) then
          call comkdis(ibn,m,np,k2-1,comexp,tcom,trant)
       endif
c-----compute cfc11 transmittance using k-distribution method
       if (f11bnd) then
          call cfckdis(m,np,k2-1,f11exp,tf11,trant)
       endif
c-----compute cfc12 transmittance using k-distribution method
       if (f12bnd) then
          call cfckdis(m,np,k2-1,f12exp,tf12,trant)
       endif
c-----compute cfc22 transmittance using k-distribution method
       if (f22bnd) then
          call cfckdis(m,np,k2-1,f22exp,tf22,trant)
       endif
c-----compute transmittance in band 10 using k-distribution method.
c     for band 10, trant is the change in transmittance due to n2o 
c     absorption.
       if (b10bnd) then
          call b10kdis(m,np,k2-1,h2oexp,conexp,co2exp,n2oexp
     *                ,th2o,tcon,tco2,tn2o,trant)
       endif
      endif
c*****   end trace gases  *****
c-----include aerosol effect
      do i=1,m
         tranal(i)=tranal(i)*taerlyr(i,k2-1)
         trant (i)=trant(i) *tranal(i)
      enddo
c***** cloud overlapping *****
      if (.not. overcast) then
        call cldovlp (m,np,k2,ict,icb,it,im,ib,
     *           cldhi,cldmd,cldlw,fcld,tcldlyr,fclr)
      else
       do i=1,m
        fclr(i)=fclr(i)*tcldlyr(i,k2-1)
       enddo
      endif
c-----compute upward and downward fluxes (bands 1-9). it follows 
c     eqs. (8.14) and (8.15). downward fluxes are positive.
      if (.not. b10bnd) then
c-----contribution from the "adjacent layer"
       if (k2 .eq. k1+1) then
        do i=1,m
         yy=min(0.999,trant(i))
         yy=max(0.001,yy)
c-hmhj use log instead of alog for default intrinsic function
         xx=(blevel(i,k1)-blevel(i,k2))/ log(yy)
         bu=(blevel(i,k1)-blevel(i,k2)*yy)/(1.0-yy)+xx
         bd=(blevel(i,k2)-blevel(i,k1)*yy)/(1.0-yy)-xx
c                bu=blayer(i,k1)
c                bd=blayer(i,k1)
c-----for clear-sky situation
         flcu(i,k1)=flcu(i,k1)-bu+(bu-blayer(i,k2))*trant(i)
         flcd(i,k2)=flcd(i,k2)+bd-(bd-blayer(i,k1-1))*trant(i)
c-----for all-sky situation
         flxu(i,k1)=flxu(i,k1)-bu+(bu-blayer(i,k2))*trant(i)*fclr(i)
         flxd(i,k2)=flxd(i,k2)+bd-(bd-blayer(i,k1-1))*trant(i)*fclr(i)
        enddo
       else
c-----contribution from distant layers.
         do i=1,m
          xx=trant(i)*dblayr(i,k2)
          flcu(i,k1) =flcu(i,k1)+xx
          flxu(i,k1) =flxu(i,k1)+xx*fclr(i)
          xx=trant(i)*dblayr(i,k1)
          flcd(i,k2) =flcd(i,k2)+xx
          flxd(i,k2) =flxd(i,k2)+xx*fclr(i)
         enddo
        endif
       else
c-----flux reduction due to n2o in band 10 (eqs. 5.1 and 5.2)
c     trant is the transmittance change due to n2o absorption (eq. 5.3).
       do i=1,m
        rflx(i,k1) = rflx(i,k1)+trant(i)*fclr(i)*dblayr(i,k2)
        rflx(i,k2) = rflx(i,k2)+trant(i)*fclr(i)*dblayr(i,k1)
        rflc(i,k1) = rflc(i,k1)+trant(i)*dblayr(i,k2)
        rflc(i,k2) = rflc(i,k2)+trant(i)*dblayr(i,k1)
       enddo
      endif
 3000 continue
c-----here, fclr and trant are, respectively, the clear line-of-sight 
c     and the transmittance between k1 and the surface.
       do i=1,m
         trantcr(i,k1) =trant(i)
         transfc(i,k1) =trant(i)*fclr(i)
       enddo
c-----compute the partial derivative of fluxes with respect to
c     surface temperature (eq. 3.12). note: upward flux is negative.
       do i=1,m
         dfdts(i,k1) =dfdts(i,k1)-dbs(i)*transfc(i,k1)
       enddo
 2000 continue
      if (.not. b10bnd) then
c-----for surface emission.
c     note: blayer(i,np+1) and dbs include the surface emissivity effect.
        do i=1,m
          flcu(i,np+1)=-blayer(i,np+1)
          flxu(i,np+1)=-blayer(i,np+1)
          sfcem(i)=sfcem(i)-blayer(i,np+1)
          dfdts(i,np+1)=dfdts(i,np+1)-dbs(i)
        enddo
c-----add the flux reflected by the surface. (last term on the
c     rhs of eq. 3.10)
        do k=1,np+1
         do i=1,m
           flcu(i,k)=flcu(i,k)-
     *          flcd(i,np+1)*trantcr(i,k)*(1.-emiss(i,ibn))
           flxu(i,k)=flxu(i,k)-
     *          flxd(i,np+1)*transfc(i,k)*(1.-emiss(i,ibn))
         enddo
        enddo
      endif
c-----summation of fluxes over spectral bands
      do k=1,np+1
       do i=1,m
         flc(i,k)=flc(i,k)+flcd(i,k)+flcu(i,k)
         flx(i,k)=flx(i,k)+flxd(i,k)+flxu(i,k)
cccshie 8/19/04
         acflxu(i,k)=acflxu(i,k)+flxu(i,k)   ! (LW upward must hold negative values)
         acflxd(i,k)=acflxd(i,k)+flxd(i,k)   ! (LW downward must hold postive values, and should=0 at top layer?)
       enddo
      enddo
c-----adjustment due to n2o absorption in band 10. eqs. (5.4) and (5.5)
       if (b10bnd) then
        do k=1,np+1
         do i=1,m
          flc(i,k)=flc(i,k)+rflc(i,k)
          flx(i,k)=flx(i,k)+rflx(i,k)
cccshie 8/19/04
ccc if rflx(i,k) upward(negative), then add adjust to upward flux
ccc if rflx(i,k) downward(positive), then add adjust to downward flux
          if(rflx(i,k).ge.0.0) acflxd(i,k)=acflxd(i,k)+rflx(i,k)
          if(rflx(i,k).lt.0.0) acflxu(i,k)=acflxu(i,k)+rflx(i,k)
c         if(k.eq.1) then  ! top
c          if(acflxd(i,k).gt.0.) acflxd(i,k)=0.0 ! LW downward flux, and should=0 at top layer?
c         endif
         enddo
        enddo
       endif
      endif                            ! endif (.not. b10bnd .or. trace)
 1000 continue
cccshie 8/19/04 based on D. Johnson GCSS Workshop
      do i=1,nx1
        rflux(i,jj2,2)=acflxd(i,np+1)    ! downward LW surface
        rflux(i,jj2,5)=acflxu(i,1)       ! upward LW TOA
        rflux(i,jj2,7)=acflxu(i,np+1)    ! upward LW surface
        rflux(i,jj2,8)=acflxd(i,1)       ! downward LW TOA
      enddo
cxp
      deallocate(acflxu)
      deallocate(acflxd)
      deallocate(pa)
      deallocate(dt)
      deallocate(sh2o)
      deallocate(swpre)
      deallocate(swtem)
      deallocate(sco3)
      deallocate(scopre)
      deallocate(scotem)
      deallocate(dh2o)
      deallocate(dcont)
      deallocate(dco2)
      deallocate(do3)
      deallocate(dn2o)
      deallocate(dch4)
      deallocate(df11)
      deallocate(df12)
      deallocate(df22)
      deallocate(th2o)
      deallocate(tcon)
      deallocate(tco2)
      deallocate(tn2o)
      deallocate(tch4)
      deallocate(tcom)
      deallocate(tf11)
      deallocate(tf12)
      deallocate(tf22)
      deallocate(h2oexp)
      deallocate(conexp)
      deallocate(co2exp)
      deallocate(n2oexp)
      deallocate(ch4exp)
      deallocate(comexp)
      deallocate(f11exp)
      deallocate(f12exp)
      deallocate(f22exp)
      deallocate(blayer)
      deallocate(blevel)
      deallocate(dblayr)
      deallocate(dbs)
      deallocate(dp)
      deallocate(cwp)
      deallocate(trant)
      deallocate(tranal)
      deallocate(transfc)
      deallocate(trantcr)
      deallocate(flxu)
      deallocate(flxd)
      deallocate(flcu)
      deallocate(flcd)
      deallocate(rflx)
      deallocate(rflc)
      deallocate(it)
      deallocate(im)
      deallocate(ib)
      deallocate(cldhi)
      deallocate(cldmd)
      deallocate(cldlw)
      deallocate(tcldlyr)
      deallocate(fclr)
      deallocate(taerlyr)
      return
      end
