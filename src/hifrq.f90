  MODULE hifrq_module

  implicit none

  private
  public :: writeout_hifrq

  integer, parameter :: fnum = 67
  integer, parameter :: varmax = 10000

  CONTAINS

!-------------------------------------------------------------------------------
!
!  hifrq:  code to write some output at a relatively high frequency
!          (compared to standard 3d output)
!
!-------------------------------------------------------------------------------

    subroutine writeout_hifrq(                                                 &
                   nstep,mtime,nwriteh,qname,dt,dosfcflx,                      &
                   icrs,icenter,jcenter,xcenter,ycenter,                       &
                   xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf,            &
                   yh,vh,rvh,yf,vf,rvf,                                        &
                   xfref,yfref,rds,sigma,rdsf,sigmaf,                          &
                   tauh,taus,zh,mh,rmh,c1,c2,tauf,zf,mf,rmf,                   &
                   rho0s,pi0s,prs0s,rth0s,                                     &
                   pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0,u0,v0,                  &
                   qi0,rr0,rf0,rrf0,                                           &
                   zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy,gx,gxu,gy,gyv,        &
                   tsk,znt,ust,thflux,qvflux,cd,ch,cq,u1,v1,s1,xland,psfc,tlh, &
                   dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,                    &
                   divx,rho,rr,rf,prs,t11,t12,t13,t22,t23,t33,                 &
                   rru,u3d,ugr ,utmp ,                                         &
                   rrv,v3d,vgr ,vtmp ,                                         &
                   rrw,w3d,wten,wtmp ,                                         &
                   pp3d,ppten,sten,th3d,sadv,thten,thten1,                     &
                   q3d,qten,kmh,kmv,khh,khv,tkea,tke3d,tketen,                 &
                   nm,defv,defh,dissten,                                       &
                   thpten,qvpten,qcpten,qipten,upten,vpten,xkzh,xkzq,xkzm,     &
                   rain,u10,v10,s10,br,brcr,hpbl,t2,q2,hfx,qfx,prate,          &
                   swten,lwten,cldfra,                                         &
                   lwupt,lwuptc,lwdnt,lwdntc,lwupb,lwupbc,lwdnb,lwdnbc,        &
                   swupt,swuptc,swdnt,swdntc,swupb,swupbc,swdnb,swdnbc,        &
                   lwcf,swcf,wprof,dumk1,dumk2,                                &
                   tdiag,qdiag,udiag,vdiag,wdiag,pdiag,out2d,out3d,getdbz,getvt, &
                   sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,flag,               &
                   dat1,dat2,dat3,reqt,reqs_s)
    use input
    use constants
    use cm1libs , only : rslf,rsif
    use adv_module , only : advs
    use bc_module
    implicit none

    integer, intent(in) :: nstep
    double precision, intent(in) :: mtime
    integer, intent(inout) :: nwriteh
    character(len=3), intent(in), dimension(maxq) :: qname
    real, intent(inout) :: dt
    logical, intent(in) :: dosfcflx
    integer, intent(in) :: icrs
    integer, intent(inout) :: icenter,jcenter
    real,    intent(inout) :: xcenter,ycenter
    real, intent(in), dimension(ib:ie) :: xh,rxh,arh1,arh2,uh,ruh
    real, intent(in), dimension(ib:ie+1) :: xf,rxf,arf1,arf2,uf,ruf
    real, intent(in), dimension(jb:je) :: yh,vh,rvh
    real, intent(in), dimension(jb:je+1) :: yf,vf,rvf
    real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
    real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
    real, intent(in), dimension(kb:ke) :: rds,sigma
    real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: tauh,taus,zh,mh,rmh,c1,c2
    real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: tauf,zf,mf,rmf
    real, intent(in), dimension(ib:ie,jb:je) :: rho0s,pi0s,prs0s,rth0s
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0
    real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u0
    real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v0
    real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: qi0,rr0,rf0,rrf0
    real, intent(in), dimension(ib:ie,jb:je) :: zs
    real, intent(in), dimension(itb:ite,jtb:jte) :: gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy
    real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gx,gxu,gy,gyv
    real, intent(in), dimension(ib:ie,jb:je) :: tsk,znt,ust,thflux,qvflux,cd,ch,cq,  &
                                                u1,v1,s1,xland,psfc,tlh
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: divx,rho,rr,rf,prs
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: t11,t12,t13,t22,t23,t33
    real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: rru,u3d,ugr,utmp
    real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: rrv,v3d,vgr,vtmp
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: rrw,w3d,wten,wtmp
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: pp3d,ppten,sten
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: th3d,sadv,thten,thten1
    real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: q3d,qten
    real, intent(inout), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
    real, intent(inout), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea,tke3d,tketen
    real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: nm,defv,defh,dissten
    real, intent(in), dimension(ibb:ieb,jbb:jeb,kbb:keb) :: thpten,qvpten,qcpten,qipten,upten,vpten
    real, intent(in), dimension(ibb:ieb,jbb:jeb,kbb:keb) :: xkzh,xkzq,xkzm
    real, intent(in), dimension(ib:ie,jb:je,nrain) :: rain
    real, intent(in), dimension(ibl:iel,jbl:jel) :: u10,v10,s10,br,brcr,hpbl,t2,q2,hfx,qfx
    real, intent(in), dimension(ib:ie,jb:je) :: prate
    real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: swten,lwten,cldfra
    real, intent(in), dimension(ibr:ier,jbr:jer) :: lwupt,lwuptc,lwdnt,lwdntc,lwupb,lwupbc,lwdnb,lwdnbc
    real, intent(in), dimension(ibr:ier,jbr:jer) :: swupt,swuptc,swdnt,swdntc,swupb,swupbc,swdnb,swdnbc
    real, intent(inout), dimension(ibr:ier,jbr:jer) :: lwcf,swcf
    real, intent(in),    dimension(kb:ke) :: wprof
    double precision, intent(inout), dimension(kb:ke) :: dumk1,dumk2
    real, intent(inout) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
    real, intent(in) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
    real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
    real, intent(in) , dimension(ibdp:iedp,jbdp:jedp,kbdp:kedp,npdiag) :: pdiag
    real, intent(inout), dimension(ib2d:ie2d,jb2d:je2d,nout2d) :: out2d
    real, intent(in) , dimension(ib3d:ie3d,jb3d:je3d,kb3d:ke3d,nout3d) :: out3d
    logical, intent(in) :: getdbz,getvt
    real, intent(inout), dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
    real, intent(inout), dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
    logical, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: flag
    real, intent(inout), dimension(ni,nj) :: dat1
    real, intent(inout), dimension(nx,ny) :: dat2
    real, intent(inout), dimension(ni,nj,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, dimension(rmp) :: reqs_s

    !---------------------------------------------------------------------------

    integer :: nvar,orec,i,j,k,n,nn,nlevels,diffit
    real :: delz,delzmin,pint,plast,qvs,tx,havg
    logical :: doit,domse
    double precision :: sum,weps,bfoo

    integer, dimension(nk) :: klev
    real, dimension(nk) :: zlev

    character(len=80) :: newstring
    character(len=80), dimension(varmax) :: varname,vardesc,varunit
    integer, dimension(varmax) :: varlvls
    character(len=80) :: a1,a2
    character(len=16) :: a16

      nvar = 0

    !---------------------------------------------------------------------------

      nlevels = 4

      zlev(1) =     0.0
      zlev(2) =  1000.0
      zlev(3) =  5000.0
      zlev(4) = 10000.0

      if(myid.eq.0) print *
      if(myid.eq.0) print *,'  levels for hifrq output: '

      do n=1,nlevels
        delzmin = 1.0e30
        do k=1,nk
          delz = abs(zh(1,1,k)-zlev(n))
          if( delz.lt.delzmin )then
            delzmin = delz
            klev(n) = k
          endif
        enddo
      enddo

      do n=1,nlevels
        if(myid.eq.0) print *,'    k,zh = ',klev(n),zh(1,1,klev(n))
      enddo

    !---------------------------------------------------------------------------
    ! open file:

    IF( myid.eq.0 )THEN

        print *,'  nwriteh = ',nwriteh

        ! grads-format
        ! (by default, for now)

        newstring = string

        newstring(totlen+1:totlen+14) = '_hf_XXXXXX.dat'

        write(newstring(totlen+5:totlen+10),201) nwriteh
201     format(i6.6)

        print *,newstring
        close(unit=fnum)
        open(unit=fnum,file=newstring,form='unformatted',access='direct',recl=4*nx*ny)

        orec = 1

    ENDIF

    !---------------------------------------------------------------------------

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'rain'
      vardesc(nvar) = 'accumulated surface rainfall'
      varunit(nvar) = 'cm'
      varlvls(nvar) = 0

      call writehf(1,rain(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN

      nvar = nvar+1
      varname(nvar) = 'prate'
      vardesc(nvar) = 'surface precipitation rate'
      varunit(nvar) = 'kg/m2/s'
      varlvls(nvar) = 0

      call writehf(1,prate,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'thflux'
      vardesc(nvar) = 'surface potential temperature flux'
      varunit(nvar) = 'K m/s'
      varlvls(nvar) = 0

      call writehf(1,thflux,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'qvflux'
      vardesc(nvar) = 'surface water vapor mixing ratio flux'
      varunit(nvar) = 'g/g m/s'
      varlvls(nvar) = 0

      call writehf(1,qvflux,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'hfx'
      vardesc(nvar) = 'surface sensible heat flux'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,hfx,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'qfx'
      vardesc(nvar) = 'surface latent heat flux'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,qfx,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'u10'
    if( imove.eq.1 )then
      vardesc(nvar) = 'u component of 10m wind speed (ground-rel.)'
    else
      vardesc(nvar) = 'u component of 10m wind speed'
    endif
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0

      call writehf(1,u10,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'v10'
    if( imove.eq.1 )then
      vardesc(nvar) = 'v component of 10m wind speed (ground-rel.)'
    else
      vardesc(nvar) = 'v component of 10m wind speed'
    endif
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0

      call writehf(1,v10,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 't2'
      vardesc(nvar) = 'diagnostic 2m temperature'
      varunit(nvar) = 'K'
      varlvls(nvar) = 0

      call writehf(1,t2,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'q2'
      vardesc(nvar) = 'diagnostic 2m mixing ratio'
      varunit(nvar) = 'kg/kg'
      varlvls(nvar) = 0

      call writehf(1,q2,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'ust'
      vardesc(nvar) = 'friction velocity (u star)'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0

      call writehf(1,ust,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'znt'
      vardesc(nvar) = 'surface roughness length'
      varunit(nvar) = 'm'
      varlvls(nvar) = 0

      call writehf(1,znt,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( sfcmodel.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'psfc'
      vardesc(nvar) = 'surface pressure'
      varunit(nvar) = 'Pa'
      varlvls(nvar) = 0

      call writehf(1,psfc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( output_dbz.eq.1 .and. qd_dbz.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'cref'
      vardesc(nvar) = 'composite reflectivity'
      varunit(nvar) = 'dbz'
      varlvls(nvar) = 0

      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = -1000.0
      enddo
      enddo

      do k=1,nk
      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = max( dum1(i,j,1) , qdiag(i,j,k,qd_dbz) )
      enddo
      enddo
      enddo

      call writehf(1,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 )THEN
      ! water paths, precipitable water:

      do j=1,nj
      do i=1,ni
        dum1(i,j,1) = 0.0
        dum1(i,j,2) = 0.0
        dum1(i,j,3) = 0.0
        dum1(i,j,4) = 0.0
      enddo
      enddo

      do k=1,nk
        if( nqv.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,1) = dum1(i,j,1) + rho(i,j,k)*q3d(i,j,k,nqv)*dz*rmh(i,j,k)
            qvs = rslf(prs(i,j,k),(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k)))
            dum1(i,j,4) = dum1(i,j,4) + rho(i,j,k)*qvs*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqc.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,2) = dum1(i,j,2) + rho(i,j,k)*q3d(i,j,k,nqc)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqr.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,2) = dum1(i,j,2) + rho(i,j,k)*q3d(i,j,k,nqr)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqs.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,3) = dum1(i,j,3) + rho(i,j,k)*q3d(i,j,k,nqs)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqg.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,3) = dum1(i,j,3) + rho(i,j,k)*q3d(i,j,k,nqg)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
        if( nqi.ge.1 )then
          do j=1,nj
          do i=1,ni
            dum1(i,j,3) = dum1(i,j,3) + rho(i,j,k)*q3d(i,j,k,nqi)*dz*rmh(i,j,k)
          enddo
          enddo
        endif
      enddo

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'prw'
      vardesc(nvar) = 'water vapor path'
      varunit(nvar) = 'kg/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'clwvi'
      vardesc(nvar) = 'condensed water path'
      varunit(nvar) = 'kg/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum1(ib,jb,2),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'clivi'
      vardesc(nvar) = 'ice water path'
      varunit(nvar) = 'kg/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum1(ib,jb,3),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'spwr'
      vardesc(nvar) = 'saturated water vapor path'
      varunit(nvar) = 'kg/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum1(ib,jb,4),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwupt'
      vardesc(nvar) = 'lw flux, upward, top of atmosphere (OLR)'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwupt,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwdnt'
      vardesc(nvar) = 'lw flux, downward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwdnt,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwupb'
      vardesc(nvar) = 'lw flux, upward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwupb,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwdnb'
      vardesc(nvar) = 'lw flux, downward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwdnb,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swupt'
      vardesc(nvar) = 'sw flux, upward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swupt,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swdnt'
      vardesc(nvar) = 'sw flux, downward, top of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swdnt,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swupb'
      vardesc(nvar) = 'sw flux, upward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swupb,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swdnb'
      vardesc(nvar) = 'sw flux, downward, bottom of atmosphere'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swdnb,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwuptc'
      vardesc(nvar) = 'lw flux, upward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwuptc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwdntc'
      vardesc(nvar) = 'lw flux, downward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwdntc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwupbc'
      vardesc(nvar) = 'lw flux, upward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwupbc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'lwdnbc'
      vardesc(nvar) = 'lw flux, downward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,lwdnbc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swuptc'
      vardesc(nvar) = 'sw flux, upward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swuptc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swdntc'
      vardesc(nvar) = 'sw flux, downward, top of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swdntc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swupbc'
      vardesc(nvar) = 'sw flux, upward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swupbc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( radopt.eq.2 )THEN
      nvar = nvar+1
      varname(nvar) = 'swdnbc'
      vardesc(nvar) = 'sw flux, downward, bottom of atmosphere - clear sky'
      varunit(nvar) = 'W/m^2'
      varlvls(nvar) = 0

      call writehf(1,swdnbc,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    doit = .true.
    IF( doit )THEN
      nvar = nvar+1
      varname(nvar) = 'wa500'
      vardesc(nvar) = 'vertical velocity at 500 mb'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = 0

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,pint,plast)
          do j=1,nj
          do i=1,ni
            pint = 1.0e30
            k = 1
            do while( pint.gt.50000.0 .and. k.lt.nk )
              plast = pint
              k = k + 1
              pint = 0.5*(prs(i,j,k-1)+prs(i,j,k))
            enddo
            dum1(i,j,1) = w3d(i,j,k-1)+(w3d(i,j,k)-w3d(i,j,k-1))  &
                                      *(50000.0-plast)  &
                                      /(pint-plast)
          enddo
          enddo

      call writehf(1,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    domse = .true.

    IF( domse .and. imoist.eq.1 )THEN

      !$omp parallel do default(shared)  &
      !$omp private(i,j)
      do j=1,nj
      do i=1,ni
        dum2(i,j,1) = 0.0
        dum3(i,j,1) = 0.0
        dum4(i,j,1) = 0.0
      enddo
      enddo

      do k=1,nk
      do j=1,nj
      do i=1,ni
        tx = (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))
        sadv(i,j,k) = cp*tx + g*zh(i,j,k)            &
                    +(lv1-lv2*tx)*q3d(i,j,k,nqv)     &
                    +((ls1-ls2*tx)-(lv1-lv2*tx))*q3d(i,j,k,nqi)
        dum2(i,j,1) = dum2(i,j,1) + rho(i,j,k)*sadv(i,j,k)*dz*rmh(i,j,k)
      enddo
      enddo
      enddo

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'fmse'
      vardesc(nvar) = 'mass-wgted vert intgrl of frzn moist static energy'
      varunit(nvar) = 'J/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum2(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      sum = 0.0

      do j=1,nj
      do i=1,ni
        sum = sum + dum2(i,j,1)
      enddo
      enddo


      havg = ( sum/dble(nx*ny) )

      do j=1,nj
      do i=1,ni
        dum2(i,j,2) = dum2(i,j,1)-havg
      enddo
      enddo

      nvar = nvar+1
      varname(nvar) = 'fmsepert'
      vardesc(nvar) = 'perturbation fmse'
      varunit(nvar) = 'J/m^2'
      varlvls(nvar) = 0

      call writehf(1,dum2(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      call bcs(sadv)

    if( td_hadv.ge.1 .and. td_vadv.ge.1 )then

        diffit = 0
        bfoo = 0.0
        weps = cp*10.0*epsilon

        call advs( 3 ,1,0,bfoo,xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,           &
                   rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                   rru,rrv,rrw,th3d,sadv,thten,0,0,dt   ,weps,                             &
                   flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                   .true.,ibdt,iedt,jbdt,jedt,kbdt,kedt,ntdiag,tdiag,td_hadv,td_vadv,td_subs, &
                   td_hidiff,td_vidiff,td_hediff,wprof,dumk1,dumk2,hadvordrs,vadvordrs)

      do k=1,nk
      do j=1,nj
      do i=1,ni
        dum3(i,j,1) = dum3(i,j,1) - tdiag(i,j,k,td_hadv)*rho(i,j,k)*dz*rmh(i,j,k)
        dum4(i,j,1) = dum4(i,j,1) - tdiag(i,j,k,td_vadv)*rho(i,j,k)*dz*rmh(i,j,k)
      enddo
      enddo
      enddo

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'hadvfmse'
      vardesc(nvar) = 'vert intgrl of horiz advection of fmse'
      varunit(nvar) = 'J/m^2/s'
      varlvls(nvar) = 0

      call writehf(1,dum3(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'vadvfmse'
      vardesc(nvar) = 'vert intgrl of vert advection of fmse'
      varunit(nvar) = 'J/m^2/s'
      varlvls(nvar) = 0

      call writehf(1,dum4(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

    endif

      !c-c-c-c-c-c-c-c-c-c

    ENDIF

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'th'
      vardesc(nvar) = 'potential temperature (K)'
      varunit(nvar) = 'K'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = th0(i,j,k)+th3d(i,j,k)
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'prs'
      vardesc(nvar) = 'pressure'
      varunit(nvar) = 'Pa'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = prs(i,j,k)
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'uinterp '
      vardesc(nvar) = 'u interpolated to scalar points (grid-relative)'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = 0.5*(u3d(i,j,k)+u3d(i+1,j,k))
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'vinterp '
      vardesc(nvar) = 'v interpolated to scalar points (grid-relative)'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = 0.5*(v3d(i,j,k)+v3d(i,j+1,k))
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

      nvar = nvar+1
      varname(nvar) = 'winterp '
      vardesc(nvar) = 'w interpolated to scalar points'
      varunit(nvar) = 'm/s'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = 0.5*(w3d(i,j,k)+w3d(i,j,k+1))
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)

      !c-c-c-c-c-c-c-c-c-c

    IF( imoist.eq.1 .and. nqv.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'qv'
      vardesc(nvar) = 'water vapor mixing ratio'
      varunit(nvar) = 'kg/kg'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = q3d(i,j,k,nqv)
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c

    IF( output_dbz.eq.1 .and. qd_dbz.ge.1 )THEN
      nvar = nvar+1
      varname(nvar) = 'dbz'
      vardesc(nvar) = 'reflectivity'
      varunit(nvar) = 'dbz'
      varlvls(nvar) = nlevels

      do n=1,nlevels
        k = klev(n)
        do j=1,nj
        do i=1,ni
          dum1(i,j,n) = qdiag(i,j,k,qd_dbz)
        enddo
        enddo
      enddo

      call writehf(nlevels,dum1(ib,jb,1),dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    ENDIF

      !c-c-c-c-c-c-c-c-c-c


    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
    ! close output file:

    id0:  IF( myid.eq.0 )THEN

        ! grads-format
        ! (by default, for now)

        ! close binary output file:
        close(unit=fnum)

        ! write descriptor file:
          newstring = string
          newstring(totlen+1:totlen+14) = '_hf.ctl       '
          open(unit=66,file=newstring)
          sstring(baselen+1:baselen+1+14) = '_hf_00%y4.dat '
          write(66,101) sstring
          write(66,102)
          write(66,103)
          write(66,104) grads_undef
            if(stretch_x.ge.1)then
              write(66,214) nx
              do i=1,nx
                write(66,217) 0.001*( 0.5*(xfref(i)+xfref(i+1)) )
              enddo
            else
              write(66,204) nx,0.001*xh(1),0.001*dx
            endif
            if(stretch_y.ge.1)then
              write(66,215) ny
              do j=1,ny
                write(66,217) 0.001*( 0.5*(yfref(j)+yfref(j+1)) )
              enddo
            else
              write(66,205) ny,0.001*yh(1),0.001*dy
            endif
            write(66,107) nlevels
            do k=1,nlevels
              write(66,217) 0.001*zh(1,1,klev(k))
            enddo
          write(66,108) nwriteh
          write(66,109) nvar
          do n=1,nvar
              a1 = varname(n)
              a2 = vardesc(n)
              !---
              a16 = '                '
              nn = len(trim(varunit(n)))
              write(a16(2:15),314) varunit(n)
              write(a16(1:1),301 )       '('
              write(a16(nn+2:nn+2),301 ) ')'
              !---
                write(66,110) a1(1:12),varlvls(n),a2(1:40),a16
          enddo
          write(66,111)
          close(unit=66)

 301    format(a1)
 314    format(a14)

 101    format('dset ^',a70)
 102    format('options template')
 103    format('title CM1 high-frequency output')
 104    format('undef ',f10.1)
 105    format('xdef ',i6,' linear ',f13.6,1x,f13.6)
 106    format('ydef ',i6,' linear 0 1')
 107    format('zdef ',i6,' levels')
 217    format(2x,f13.6)
 108    format('tdef ',i10,' linear 00:00Z03JUL0001 1YR')
 109    format('vars ',i6)
 110    format(a12,2x,i6,' 99 ',a40,1x,a16)
 111    format('endvars')

 204    format('xdef ',i6,' linear ',f13.6,1x,f13.6)
 205    format('ydef ',i6,' linear ',f13.6,1x,f13.6)

 214    format('xdef ',i6,' levels ')
 215    format('ydef ',i6,' levels ')


    ENDIF  id0


    end subroutine writeout_hifrq


  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

    subroutine writehf(nout,var,dat1,dat2,dat3,reqt,orec,nvar,varname,vardesc,varunit)
    use input
    implicit none

    integer, intent(in) :: nout
    real, intent(in), dimension(ib:ie,jb:je,nout) :: var
    real, intent(inout), dimension(ni,nj) :: dat1
    real, intent(inout), dimension(nx,ny) :: dat2
    real, intent(inout), dimension(ni,nj,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(inout) :: orec
    integer, intent(in) :: nvar
    character(len=80), intent(in), dimension(varmax) :: varname,vardesc,varunit

    integer :: i,j,k

    if(myid.eq.0) print *,nvar,trim(varname(nvar))

    DO k = 1 , nout

      call gather(var(ib,jb,k),dat1(1,1),dat2(1,1),dat3(1,1,0),reqt)

      if( myid.eq.0 )then

        ! grads-format file:

        write(fnum,rec=orec) ((dat2(i,j),i=1,nx),j=1,ny)
        orec=orec+1

      endif

    ENDDO

    end subroutine writehf


  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine gather(var,dat1,dat2,dat3,reqt)
    use input
    implicit none

    real, intent(in), dimension(ib:ie,jb:je) :: var
    real, intent(inout), dimension(ni,nj) :: dat1
    real, intent(inout), dimension(nx,ny) :: dat2
    real, intent(inout), dimension(ni,nj,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt

    !----

    integer :: i,j

    !-------------------------------------------------------------------
    ! This subroutine collects data (from other processors if this is a
    ! MPI run) 
    !-------------------------------------------------------------------


      !-------------------- non-MPI section --------------------!
!$omp parallel do default(shared)   &
!$omp private(i,j)
      do j=1,nj
      do i=1,ni
        dat2(i,j)=var(i,j)
      enddo
      enddo


      end subroutine gather


  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


  END MODULE hifrq_module
