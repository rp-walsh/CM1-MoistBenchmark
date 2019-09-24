  MODULE writeout_module

  implicit none

  private
  public :: setup_output,writeout


  CONTAINS

      subroutine setup_output(tdef,qname,qunit,budname,   &
                              name_output,desc_output,unit_output,grid_output,cmpr_output,  &
                              xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,dosfcflx)
      use input
      implicit none

      !-------------------------------------------------------------------------------
      ! This subroutine gets things ready for 3d writeout files
      !   since cm1r19: unified grads-format and netcdf-format variable descriptions
      !                 use "_output" arrays for both
      !-------------------------------------------------------------------------------

      character(len=15), intent(inout) :: tdef
      character(len=3), intent(in), dimension(maxq) :: qname
      character(len=20), intent(in), dimension(maxq) :: qunit
      character(len=6), intent(in), dimension(maxq) :: budname
      character(len=60), intent(inout), dimension(maxvars) :: desc_output
      character(len=40), intent(inout), dimension(maxvars) :: name_output,unit_output
      character(len=1),  intent(inout), dimension(maxvars) :: grid_output
      logical, intent(inout), dimension(maxvars) :: cmpr_output
      real, intent(in), dimension(ib:ie) :: xh
      real, intent(in), dimension(ib:ie+1) :: xf
      real, intent(in), dimension(jb:je) :: yh
      real, intent(in), dimension(jb:je+1) :: yf
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(kb:ke+1) :: sigmaf
      logical, intent(in) :: dosfcflx

      integer :: i,j,k,n,nn,flag
      logical :: doit
      character(len=8) :: text1
      character(len=30) :: text2

      maxk = min(maxk,nk)
      n_out = 0

!-----------------------------------------------------------------------
! get length of output_path string

    flag=0
    n=0
    do while( flag.eq.0 .and. n.le.70 )
      n=n+1
      if( output_path(n:n).eq.' ' .or. output_path(n:n).eq.'.' ) flag=1
    enddo

    strlen=n-1

!--------------------------------------
! get length of output_basename string

    flag=0
    n=0
    do while( flag.eq.0 .and. n.le.70 )
      n=n+1
      if( output_basename(n:n).eq.' ' .or. output_basename(n:n).eq.'.' ) flag=1
    enddo

    baselen=n-1

!------

    totlen = strlen + baselen

    IF( totlen .gt. (70-22) )THEN
      IF(myid.eq.0)THEN
      print *
      print *,'  baselen = ',baselen
      print *,'  strlen  = ',strlen
      print *,'  totlen  = ',totlen
      print *
      print *,'  totlen is too long ... make either baselen or strlen shorter '
      print *
      print *,'  stopping cm1 .... '
      print *
      ENDIF
      call stopcm1
    ENDIF

!------

      string = '                                                                      '
    statfile = '                                                                      '
     sstring = '                                                                      '

  if(strlen.gt.0)then
      string(1:strlen) = output_path(1:strlen)
    statfile(1:strlen) = output_path(1:strlen)
  endif

      string(strlen+1:strlen+baselen) = output_basename(1:baselen)
    statfile(strlen+1:strlen+baselen) = output_basename(1:baselen)
     sstring(1:baselen) = output_basename(1:baselen)

    statfile(totlen+1:totlen+22) = '_stats.dat            '

  IF(output_format.eq.1)THEN
    if(dowr) write(outfile,*)
    if(dowr) write(outfile,*) '  writing ctl files ... '
  ENDIF
    if(dowr) write(outfile,*)
    if(dowr) write(outfile,*) '  strlen          = ',strlen
    if(dowr) write(outfile,*) '  baselen         = ',baselen
    if(dowr) write(outfile,*) '  totlen          = ',totlen
  if(strlen.gt.0)then
    if(dowr) write(outfile,*) '  output_path     = ',output_path(1:strlen)
  endif
    if(dowr) write(outfile,*) '  output_basename = ',output_basename(1:baselen)
    if(dowr) write(outfile,*) '  statfile        = ',statfile
    if(dowr) write(outfile,*)

      IF( myid.eq.0 )THEN
        if(output_filetype.ge.2)then
          tdef = '00:00Z03JUL0001'
        else
          tdef = '00:00Z03JUL2000'
        endif
        IF( radopt.ge.1 )THEN
          write(tdef( 1: 2),237) hour
          write(tdef( 4: 5),237) minute
          write(tdef( 7: 8),237) day
        if(output_filetype.ge.2)then
          write(tdef(12:15),238) 1
        else
          write(tdef(12:15),238) year
        endif
237       format(i2.2)
238       format(i4.4)
          IF( month.eq.1 )THEN
            write(tdef(9:11),239) 'JAN'
          ELSEIF( month.eq.2 )THEN
            write(tdef(9:11),239) 'FEB'
          ELSEIF( month.eq.3 )THEN
            write(tdef(9:11),239) 'MAR'
          ELSEIF( month.eq.4 )THEN
            write(tdef(9:11),239) 'APR'
          ELSEIF( month.eq.5 )THEN
            write(tdef(9:11),239) 'MAY'
          ELSEIF( month.eq.6 )THEN
            write(tdef(9:11),239) 'JUN'
          ELSEIF( month.eq.7 )THEN
            write(tdef(9:11),239) 'JUL'
          ELSEIF( month.eq.8 )THEN
            write(tdef(9:11),239) 'AUG'
          ELSEIF( month.eq.9 )THEN
            write(tdef(9:11),239) 'SEP'
          ELSEIF( month.eq.10 )THEN
            write(tdef(9:11),239) 'OCT'
          ELSEIF( month.eq.11 )THEN
            write(tdef(9:11),239) 'NOV'
          ELSEIF( month.eq.12 )THEN
            write(tdef(9:11),239) 'DEC'
          ELSE
            print *
            print *,'  Invalid value for MONTH '
            print *
            print *,'  Stopping CM1 .... '
            print *
            call stopcm1
          ENDIF
239       format(a3)
        ENDIF
      ENDIF

!-----------------------------------------------------------------------
!  Begin:  define output variables:
!-----------------------------------------------------------------------

!----------------------------
! 2d vars:

    if(output_rain   .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'rain    '
      desc_output(n_out) = 'accumulated surface rainfall'
      unit_output(n_out) = 'cm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      cmpr_output(n_out) = .true.
    endif
    if(output_rain   .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'prate'
      desc_output(n_out) = 'surface precipitation rate'
      unit_output(n_out) = 'kg/m2/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      cmpr_output(n_out) = .true.
    endif
    if(output_sws    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'sws     '
      desc_output(n_out) = 'max horiz wind speed at lowest model level'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_svs    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'svs     '
      desc_output(n_out) = 'max vert vorticity at lowest model level'
      unit_output(n_out) = '1/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sps    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'sps     '
      desc_output(n_out) = 'min pressure at lowest model level'
      unit_output(n_out) = 'Pa'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_srs    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'srs     '
      desc_output(n_out) = 'max qr at lowest model level'
      unit_output(n_out) = 'kg/kg'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sgs    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'sgs     '
      desc_output(n_out) = 'max qg at lowest model level'
      unit_output(n_out) = 'kg/kg'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sus    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'sus     '
      desc_output(n_out) = 'max w at 5 km AGL'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_shs    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'shs     '
      desc_output(n_out) = 'max integrated updraft helicity'
      unit_output(n_out) = 'm2/s2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(nrain.eq.2)then
      if(output_rain   .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'rain2   '
        desc_output(n_out) = 'translated surface rainfall'
        unit_output(n_out) = 'cm'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_sws    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'sws2    '
        desc_output(n_out) = 'translated max horiz wspd at lowest model level'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_svs    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'svs2    '
        desc_output(n_out) = 'translated max vert vort at lowest model level'
        unit_output(n_out) = '1/s'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_sps    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'sps2    '
        desc_output(n_out) = 'translated min pressure at lowest model level'
        unit_output(n_out) = 'Pa'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_srs    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'srs2    '
        desc_output(n_out) = 'translated max qr at lowest model level'
        unit_output(n_out) = 'kg/kg'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_sgs    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'sgs2    '
        desc_output(n_out) = 'translated max qg at lowest model level'
        unit_output(n_out) = 'kg/kg'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_sus    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'sus2    '
        desc_output(n_out) = 'translated max w at 5 km AGL'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if(output_shs    .eq.1)then
        n_out = n_out + 1
        name_output(n_out) = 'shs2    '
        desc_output(n_out) = 'translated max integrated updraft helicity'
        unit_output(n_out) = 'm2/s2'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
    endif
    if(output_uh.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'uh      '
      desc_output(n_out) = 'integrated (2-5 km) AGL) updraft helicity'
      unit_output(n_out) = 'm2/s2'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_coldpool.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'cpc     '
      desc_output(n_out) = 'cold pool intensity C'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'cph     '
      desc_output(n_out) = 'cold pool depth h'
      unit_output(n_out) = 'm AGL'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sfcflx .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'thflux  '
      desc_output(n_out) = 'surface potential temperature flux'
      unit_output(n_out) = 'K m/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qvflux  '
      desc_output(n_out) = 'surface water vapor mixing ratio flux'
      unit_output(n_out) = 'g/g m/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tsk     '
      desc_output(n_out) = 'soil/ocean temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sfcparams.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'cd      '
      desc_output(n_out) = 'sfc exchange coeff for momentum'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'ch      '
      desc_output(n_out) = 'sfc exchange coeff for sensible heat'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'cq      '
      desc_output(n_out) = 'sfc exchange coeff for moisture'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tlh     '
      desc_output(n_out) = 'horiz lengthscale for turbulence scheme'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( betaplane.eq.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'f2d'
      desc_output(n_out) = 'Coriolis parameter'
      unit_output(n_out) = '1/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_psfc   .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'psfc    '
      desc_output(n_out) = 'surface pressure'
      unit_output(n_out) = 'Pa'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_zs     .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'zs      '
      desc_output(n_out) = 'terrain height'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_dbz    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'cref    '
      desc_output(n_out) = 'composite reflectivity'
      unit_output(n_out) = 'dBZ'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      cmpr_output(n_out) = .true.
    endif
    if(output_sfcparams.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'xland   '
      desc_output(n_out) = 'land/water flag (1=land,2=water)'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lu      '
      desc_output(n_out) = 'land use index'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'mavail  '
      desc_output(n_out) = 'surface moisture availability '
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if((output_sfcparams.eq.1).and.(sfcmodel.eq.2.or.sfcmodel.eq.3.or.sfcmodel.eq.4.or.oceanmodel.eq.2))then
      n_out = n_out + 1
      name_output(n_out) = 'tmn     '
      desc_output(n_out) = 'deep-layer soil temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if((output_sfcparams.eq.1).and.(sfcmodel.ge.1.or.oceanmodel.eq.2))then
      n_out = n_out + 1
      name_output(n_out) = 'hfx     '
      desc_output(n_out) = 'surface sensible heat flux'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qfx     '
      desc_output(n_out) = 'surface moisture flux'
      unit_output(n_out) = 'kg/m^2/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if((output_sfcparams.eq.1).and.(sfcmodel.eq.2.or.sfcmodel.eq.3.or.sfcmodel.eq.4.or.oceanmodel.eq.2))then
      n_out = n_out + 1
      name_output(n_out) = 'gsw     '
      desc_output(n_out) = 'downward SW flux at surface'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'glw     '
      desc_output(n_out) = 'downward LW flux at surface'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if((output_sfcparams.eq.1).and.(sfcmodel.eq.2.or.sfcmodel.eq.3.or.sfcmodel.eq.4))then
      n_out = n_out + 1
      name_output(n_out) = 'tslb1   '
      desc_output(n_out) = 'soil temperature, layer 1'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tslb2   '
      desc_output(n_out) = 'soil temperature, layer 2'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tslb3   '
      desc_output(n_out) = 'soil temperature, layer 3'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tslb4   '
      desc_output(n_out) = 'soil temperature, layer 4'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'tslb5   '
      desc_output(n_out) = 'soil temperature, layer 5'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_sfcparams.eq.1.and.oceanmodel.eq.2)then
      n_out = n_out + 1
      name_output(n_out) = 'tml     '
      desc_output(n_out) = 'ocean mixed layer temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'hml     '
      desc_output(n_out) = 'ocean mixed layer depth'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'huml    '
      desc_output(n_out) = 'ocean mixed layer u velocity'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'hvml    '
      desc_output(n_out) = 'ocean mixed layer v velocity'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( output_sfcparams.eq.1 .and. radopt.ge.1 )then

    IF( radopt.eq.1 )THEN
      ! nasa-goddard vars:
      n_out = n_out + 1
      name_output(n_out) = 'radsw   '
      desc_output(n_out) = 'solar radiation at surface'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'rnflx   '
      desc_output(n_out) = 'net radiation absorbed by surface'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'radswnet'
      desc_output(n_out) = 'net solar radiation'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'radlwin '
      desc_output(n_out) = 'incoming longwave radiation'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
! MS addition - toa fluxes
      n_out = n_out + 1
      name_output(n_out) = 'olr     '
      desc_output(n_out) = 'TOA net outgoing longwave radiation'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'dsr     '
      desc_output(n_out) = 'TOA net incoming solar radiation'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    ENDIF
    !c-c-c-c-c!
    IF( radopt.ge.2 )THEN
      n_out = n_out + 1
      name_output(n_out) = 'lwupt'
      desc_output(n_out) = 'lw flux, upward, top of atmosphere (OLR)'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lwdnt'
      desc_output(n_out) = 'lw flux, downward, top of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lwupb'
      desc_output(n_out) = 'lw flux, upward, bottom of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lwdnb'
      desc_output(n_out) = 'lw flux, downward, bottom of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'swupt'
      desc_output(n_out) = 'sw flux, upward, top of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'swdnt'
      desc_output(n_out) = 'sw flux, downward, top of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'swupb'
      desc_output(n_out) = 'sw flux, upward, bottom of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'swdnb'
      desc_output(n_out) = 'sw flux, downward, bottom of atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      ! cloud forcing vars:
      n_out = n_out + 1
      name_output(n_out) = 'lwcf'
      desc_output(n_out) = 'longwave cloud forcing at top-of-atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'swcf'
      desc_output(n_out) = 'shortwave cloud forcing at top-of-atmosphere'
      unit_output(n_out) = 'W/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    ENDIF

    endif
    IF(output_sfcdiags.eq.1)THEN
      n_out = n_out + 1
      name_output(n_out) = 'u10     '
    if( imove.eq.1 )then
      desc_output(n_out) = 'diagnostic 10m u wind speed (ground-rel.)'
    else
      desc_output(n_out) = 'diagnostic 10m u wind speed'
    endif
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'v10     '
    if( imove.eq.1 )then
      desc_output(n_out) = 'diagnostic 10m v wind speed (ground-rel.)'
    else
      desc_output(n_out) = 'diagnostic 10m v wind speed'
    endif
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 's10'
      desc_output(n_out) = 's10'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 't2      '
      desc_output(n_out) = 'diagnostic 2m temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'q2      '
      desc_output(n_out) = 'diagnostic 2m mixing ratio'
      unit_output(n_out) = 'g/g'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'znt     '
      desc_output(n_out) = 'roughness length'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'ust     '
      desc_output(n_out) = 'friction velocity'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    if( dosfcflx .or. ipbl.eq.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'tst'
      desc_output(n_out) = 'theta-star (pot temp scaling parameter in similarity theory)'
      unit_output(n_out) = 'K'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qst'
      desc_output(n_out) = 'q-star (water vapor scaling parameter in similarity theory)'
      unit_output(n_out) = 'g/g'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
      n_out = n_out + 1
      name_output(n_out) = 'hpbl    '
  IF( testcase.ge.1 .and. testcase.le.7 )THEN
      desc_output(n_out) = 'PBL height (using max theta gradient)'
  ELSE
      desc_output(n_out) = 'diagnosed PBL height'
  ENDIF
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

      n_out = n_out + 1
      name_output(n_out) = 'zol     '
      desc_output(n_out) = 'z/L (z over Monin-Obukhov length)'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'mol'
      desc_output(n_out) = 'Monin-Obukhov length (L)'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'br      '
      desc_output(n_out) = 'bulk Richardson number in surface layer'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!!!      n_out = n_out + 1
!!!      name_output(n_out) = 'brcr'
!!!      desc_output(n_out) = 'critical bulk Richardson number in surface layer'
!!!      unit_output(n_out) = 'nondimensional'
!!!      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'psim    '
      desc_output(n_out) = 'similarity stability function (momentum) at lowest model level'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'psih    '
      desc_output(n_out) = 'similarity stability function (heat) at lowest model level'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'psiq    '
      desc_output(n_out) = 'similarity stability function (moisture) at lowest model level'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qsfc    '
      desc_output(n_out) = 'land/ocean water vapor mixing ratio'
      unit_output(n_out) = 'g/g'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'wspd    '
      desc_output(n_out) = 'sfc layer wind speed (with gust)   '
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    ENDIF

    IF( imoist.eq.1 .and. output_lwp.eq.1 )THEN

      n_out = n_out + 1
      name_output(n_out) = 'cwp     '
      desc_output(n_out) = 'cloud water path'
      unit_output(n_out) = 'kg/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

      n_out = n_out + 1
      name_output(n_out) = 'lwp     '
      desc_output(n_out) = 'liquid water path'
      unit_output(n_out) = 'kg/m^2'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

    ENDIF

    IF( imoist.eq.1 .and. output_pwat.eq.1 )THEN

      n_out = n_out + 1
      name_output(n_out) = 'pwat    '
      desc_output(n_out) = 'precipitable water'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

    ENDIF

    IF( imoist.eq.1 )THEN
    IF( output_cape.eq.1 .or. output_cin.eq.1 .or. output_lcl.eq.1 .or. output_lfc.eq.1 )THEN
      n_out = n_out + 1
      name_output(n_out) = 'cape    '
      desc_output(n_out) = 'convective available potential energy'
      unit_output(n_out) = 'J/kg'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'cin     '
      desc_output(n_out) = 'convective inhibition'
      unit_output(n_out) = 'J/kg'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lcl     '
      desc_output(n_out) = 'lifted condensation level'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lfc     '
      desc_output(n_out) = 'level of free convection'
      unit_output(n_out) = 'm'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    ENDIF
    ENDIF


    doit = .false.
    if( doit )then
    if( pmin.lt.40000.0 )then
      n_out = n_out + 1
      name_output(n_out) = 'wa500   '
      desc_output(n_out) = 'vertical velocity at 500 mb'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    endif


    ! arbitrary output (out2d array)
    out2dcheck:  &
    IF( nout2d.ge.1 .and. ie2d.gt.1 .and. je2d.gt.1 )THEN
      do n=1,nout2d
        n_out = n_out + 1
        text1 = 'out2d   '
        if(n.lt.10)then
          write(text1(6:6),211) n
        elseif(n.lt.100)then
          write(text1(6:7),212) n
        elseif(n.lt.1000)then
          write(text1(6:8),213) n
        else
          print *,'  nout2d is too large '
          call stopcm1
        endif
        name_output(n_out) = text1
        desc_output(n_out) = '2d output'
        unit_output(n_out) = 'unknown'
        grid_output(n_out) = '2'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      enddo
    ENDIF  out2dcheck


    ! done with 2d variables

!----------------------------
! 3d scalar vars:

    if(output_zh     .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'zh      '
      desc_output(n_out) = 'height on model levels'
      unit_output(n_out) = 'm'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_th     .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'th      '
      desc_output(n_out) = 'potential temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_thpert .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'thpert  '
      desc_output(n_out) = 'potential temperature perturbation'
      unit_output(n_out) = 'K'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_prs    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'prs     '
      desc_output(n_out) = 'pressure'
      unit_output(n_out) = 'Pa'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_prspert.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'prspert '
      desc_output(n_out) = 'pressure perturbation'
      unit_output(n_out) = 'Pa'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_pi     .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'pi      '
      desc_output(n_out) = 'nondimensional pressure'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_pipert .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'pipert  '
      desc_output(n_out) = 'nondimensional pressure perturbation'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( psolver.eq.4 )then
      n_out = n_out + 1
      name_output(n_out) = 'phi'
      desc_output(n_out) = 'pressure variable for anelastic equations'
      unit_output(n_out) = 'm2/s2'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( psolver.eq.5 )then
      n_out = n_out + 1
      name_output(n_out) = 'phi'
      desc_output(n_out) = 'pressure variable for incompressible equations'
      unit_output(n_out) = 'm2/s2'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( psolver.eq.6 )then
      n_out = n_out + 1
      name_output(n_out) = 'phi'
      desc_output(n_out) = 'pressure variable for compr.-Bouss. equations'
      unit_output(n_out) = 'm2/s2'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_rho    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'rho     '
      desc_output(n_out) = 'dry-air density'
      unit_output(n_out) = 'kg/m^3'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_rhopert.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'rhopert '
      desc_output(n_out) = 'dry-air density perturbation'
      unit_output(n_out) = 'kg/m^3'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(iptra         .eq.1)then
      do n=1,npt
        text1='pt      '
        if(n.le.9)then
          write(text1(3:3),155) n
155       format(i1.1)
        elseif(n.le.99)then
          write(text1(3:4),154) n
154       format(i2.2)
        else
          write(text1(3:5),153) n
153       format(i3.3)
        endif
        n_out = n_out + 1
        name_output(n_out) = text1
        desc_output(n_out) = 'passive tracer mixing ratio'
        unit_output(n_out) = 'kg/kg'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
        cmpr_output(n_out) = .true.
      enddo
    endif
    if(output_qv     .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'qv      '
      desc_output(n_out) = 'water vapor mixing ratio'
      unit_output(n_out) = 'kg/kg'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_qvpert .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'qvpert  '
      desc_output(n_out) = 'water vapor mixing ratio perturbation'
      unit_output(n_out) = 'kg/kg'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_q      .eq.1)then
      do n=1,numq
        if(n.ne.nqv)then
          text1='        '
          text2='                              '
          write(text1(1:3),156) qname(n)
          write(text2(1:3),156) qname(n)
156       format(a3)
          n_out = n_out + 1
          name_output(n_out) = text1
          desc_output(n_out) = text2
          unit_output(n_out) = qunit(n)
          grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
          cmpr_output(n_out) = .true.
        endif
      enddo
    endif
    if(output_dbz    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'dbz     '
      desc_output(n_out) = 'reflectivity'
      unit_output(n_out) = 'dBZ'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      cmpr_output(n_out) = .true.
    endif
    if(output_buoyancy.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'buoyancy'
      desc_output(n_out) = 'buoyancy'
      unit_output(n_out) = 'm/s^2'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_uinterp.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'uinterp '
      desc_output(n_out) = 'u interpolated to scalar points (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_vinterp.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'vinterp '
      desc_output(n_out) = 'v interpolated to scalar points (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_winterp.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'winterp '
      desc_output(n_out) = 'w interpolated to scalar points'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_vort.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'xvort   '
      desc_output(n_out) = 'horizontal vorticity (x)'
      unit_output(n_out) = '1/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'yvort   '
      desc_output(n_out) = 'horizontal vorticity (y)'
      unit_output(n_out) = '1/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'zvort   '
      desc_output(n_out) = 'vertical vorticity'
      unit_output(n_out) = '1/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_pv.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'pv      '
      desc_output(n_out) = 'potential vorticity'
      unit_output(n_out) = 'K m2/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_basestate.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'pi0     '
      desc_output(n_out) = 'base-state nondimensional pressure'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'th0     '
      desc_output(n_out) = 'base-state potential temperature'
      unit_output(n_out) = 'K'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'prs0    '
      desc_output(n_out) = 'base-state pressure'
      unit_output(n_out) = 'Pa'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qv0     '
      desc_output(n_out) = 'base-state water vapor mixing ratio'
      unit_output(n_out) = 'kg/kg'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_pblten.eq.1 .and. ipbl.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'qcpten  '
      desc_output(n_out) = 'pbl tendency: cloudwater mixing ratio'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'qipten  '
      desc_output(n_out) = 'pbl tendency: cloud ice mixing ratio'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif

    radcheck1:  &
    if(output_radten.eq.1)then

      n_out = n_out + 1
      name_output(n_out) = 'swten   '
      desc_output(n_out) = 'temperature tendency, sw radiation'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'lwten   '
      desc_output(n_out) = 'temperature tendency, lw radiation'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

    radcheck2:  &
    if( radopt.eq.1 .or. radopt.eq.2 )then
      n_out = n_out + 1
      name_output(n_out) = 'cldfra  '
      desc_output(n_out) = 'cloud fraction from radiation scheme'
      unit_output(n_out) = 'nondimensional'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!      if( doeff )then
!        n_out = n_out + 1
!        name_output(n_out) = 'effc'
!        desc_output(n_out) = 'effc'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!        n_out = n_out + 1
!        name_output(n_out) = 'effi'
!        desc_output(n_out) = 'effi'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!        n_out = n_out + 1
!        name_output(n_out) = 'effs'
!        desc_output(n_out) = 'effs'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!      if( radopt.eq.1 .and. ptype.eq.5 )then
!        n_out = n_out + 1
!        name_output(n_out) = 'effr'
!        desc_output(n_out) = 'effr'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!        n_out = n_out + 1
!        name_output(n_out) = 'effg'
!        desc_output(n_out) = 'effg'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!        n_out = n_out + 1
!        name_output(n_out) = 'effis'
!        desc_output(n_out) = 'effis'
!        unit_output(n_out) = 'micron'
!        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
!      endif
!      endif
    endif  radcheck2

    endif  radcheck1


    ! arbitrary output (out3d array)
    out3dcheck:  &
    IF( nout3d.ge.1 .and. ie3d.gt.1 .and. je3d.gt.1 .and. ke3d.gt.1 )THEN
      do n=1,nout3d
        n_out = n_out + 1
        text1 = 'out     '
        if(n.lt.10)then
          write(text1(4:4),211) n
211       format(i1.1)
        elseif(n.lt.100)then
          write(text1(4:5),212) n
212       format(i2.2)
        elseif(n.lt.1000)then
          write(text1(4:6),213) n
213       format(i3.3)
        elseif(n.lt.10000)then
          write(text1(4:7),214) n
214       format(i4.4)
        elseif(n.lt.100000)then
          write(text1(4:8),215) n
215       format(i5.5)
        else
          print *,'  nout3d is too large '
          call stopcm1
        endif
        name_output(n_out) = text1
        desc_output(n_out) = '3d output'
        unit_output(n_out) = 'unknown'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      enddo
    ENDIF  out3dcheck


  IF( output_thbudget.eq.1 )THEN
    if( td_hadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_hadv'
      if( hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 )then
        desc_output(n_out) = 'pt budget: horiz advection (non-diff component)'
      else
        desc_output(n_out) = 'pot temp budget: horiz advection'
      endif
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_vadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_vadv'
      if( vadvordrs.eq.3 .or. vadvordrs.eq.5 .or. vadvordrs.eq.7 .or. vadvordrs.eq.9 .or. advwenos.ge.1 )then
        desc_output(n_out) = 'pt budget: vert advection (non-diff component)'
      else
        desc_output(n_out) = 'pot temp budget: vert advection'
      endif
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_hidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_hidiff'
      desc_output(n_out) = 'pot temp budget: horiz implicit diffusion'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_vidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_vidiff'
      desc_output(n_out) = 'pot temp budget: vert implicit diffusion'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_hediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_hediff'
      desc_output(n_out) = 'pot temp budget: horiz explicit diffusion'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_vediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_vediff'
      desc_output(n_out) = 'pot temp budget: vert explicit diffusion'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_hturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_hturb'
      desc_output(n_out) = 'pot temp budget: horiz parameterized turbulence'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_vturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_vturb'
      desc_output(n_out) = 'pot temp budget: vert parameterized turbulence'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_mp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_mp'
      desc_output(n_out) = 'pot temp budget: microphysics scheme'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_rdamp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_rdamp'
      desc_output(n_out) = 'pot temp budget: Rayleigh damper'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_rad.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_rad'
      desc_output(n_out) = 'pot temp budget: radiation scheme'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_div.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_div'
      desc_output(n_out) = 'pot temp budget: moist divergence term'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_diss.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_diss'
      desc_output(n_out) = 'pot temp budget: dissipative heating'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_pbl.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_pbl'
      desc_output(n_out) = 'pot tem. budget: PBL scheme'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( td_subs.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ptb_subs'
      desc_output(n_out) = 'pot temp budget: large-scale subsidence'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( ptype.eq.5 )then
      if( td_cond.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_cond'
        desc_output(n_out) = 'theta tendency: condensation'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_evac.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_evac'
        desc_output(n_out) = 'theta tendency: cloudwater evaporation'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_evar.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_evar'
        desc_output(n_out) = 'theta tendency: rainwater evaporation'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_dep.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_dep'
        desc_output(n_out) = 'theta tendency: deposition'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_subl.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_subl'
        desc_output(n_out) = 'theta tendency: sublimation'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_melt.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_melt'
        desc_output(n_out) = 'theta tendency: melting'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( td_frz.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'tt_frz'
        desc_output(n_out) = 'theta tendency: freezing'
        unit_output(n_out) = 'K/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
    endif
    if( td_efall.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'td_efall'
      desc_output(n_out) = 'temp. tendency: energy fallout terms'
      unit_output(n_out) = 'K/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
  ENDIF
    IF( output_fallvel.eq.1 )THEN
      if( qd_vtc.gt.0 )then
        n_out = n_out + 1
        name_output(n_out) = 'vtc     '
        desc_output(n_out) = 'terminal fall velocity: qc'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_vtr.gt.0 )then
        n_out = n_out + 1
        name_output(n_out) = 'vtr     '
        desc_output(n_out) = 'terminal fall velocity: qr'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_vts.gt.0 )then
        n_out = n_out + 1
        name_output(n_out) = 'vts     '
        desc_output(n_out) = 'terminal fall velocity: qs'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_vtg.gt.0 )then
        n_out = n_out + 1
        name_output(n_out) = 'vtg     '
        desc_output(n_out) = 'terminal fall velocity: qg'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_vti.gt.0 )then
        n_out = n_out + 1
        name_output(n_out) = 'vti     '
        desc_output(n_out) = 'terminal fall velocity: qi'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
    ENDIF
  IF( output_qvbudget.eq.1 )THEN
    if( qd_hadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_hadv'
      if( hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 )then
        desc_output(n_out) = 'qv budget: horizontal advection (non-diff component)'
      else
        desc_output(n_out) = 'qv budget: horizontal advection'
      endif
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_vadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_vadv'
      if( vadvordrs.eq.3 .or. vadvordrs.eq.5 .or. vadvordrs.eq.7 .or. vadvordrs.eq.9 .or. advwenos.ge.1 )then
        desc_output(n_out) = 'qv budget: vertical advection (non-diff component)'
      else
        desc_output(n_out) = 'qv budget: vertical advection'
      endif
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_hidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_hidiff'
      desc_output(n_out) = 'qv budget: horiz implicit diffusion'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_vidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_vidiff'
      desc_output(n_out) = 'qv budget: vert implicit diffusion'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_hediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_hediff'
      desc_output(n_out) = 'qv budget: horiz explicit diffusion'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_vediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_vediff'
      desc_output(n_out) = 'qv budget: vert explicit diffusion'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_hturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_hturb'
      desc_output(n_out) = 'qv budget: horizontal parameterized turbulence'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_vturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_vturb'
      desc_output(n_out) = 'qv budget: vertical parameterized turbulence'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_mp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_mp'
      desc_output(n_out) = 'qv budget: microphysics scheme'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_pbl.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_pbl'
      desc_output(n_out) = 'qv budget: PBL scheme'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( qd_subs.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'qvb_subs'
      desc_output(n_out) = 'qv budget: large-scale subsidence'
      unit_output(n_out) = 'kg/kg/s'
      grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if( ptype.eq.5 )then
      if( qd_cond.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'qt_cond'
        desc_output(n_out) = 'qv tendency: condensation'
        unit_output(n_out) = 'kg/kg/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_evac.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'qt_evac'
        desc_output(n_out) = 'qv tendency: cloudwater evaporation'
        unit_output(n_out) = 'kg/kg/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_evar.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'qt_evar'
        desc_output(n_out) = 'qv tendency: rainwater evaporation'
        unit_output(n_out) = 'kg/kg/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_dep.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'qt_dep'
        desc_output(n_out) = 'qv tendency: deposition'
        unit_output(n_out) = 'kg/kg/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      if( qd_subl.ge.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'qt_subl'
        desc_output(n_out) = 'qv tendency: sublimation'
        unit_output(n_out) = 'kg/kg/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
    endif
  ENDIF

      IF( pdcomp )THEN

        n_out = n_out + 1
        name_output(n_out) = 'pipb'
        desc_output(n_out) = 'diagnosed pi-prime: buoyancy component'
        unit_output(n_out) = 'nondimensional'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        n_out = n_out + 1
        name_output(n_out) = 'pipdl'
        desc_output(n_out) = 'diagnosed pi-prime: linear dynamic component'
        unit_output(n_out) = 'nondimensional'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        n_out = n_out + 1
        name_output(n_out) = 'pipdn'
        desc_output(n_out) = 'diagnosed pi-prime: nonlinear dynamic component'
        unit_output(n_out) = 'nondimensional'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        if( icor.eq.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'pipc'
        desc_output(n_out) = 'diagnosed pi-prime: Coriolis component'
        unit_output(n_out) = 'nondimensional'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
        endif

      ENDIF


      IF( axisymm.eq.1 )THEN
        n_out = n_out + 1
        name_output(n_out) = 'vgrad'
        desc_output(n_out) = 'gradient wind speed'
        unit_output(n_out) = 'm/s'
        grid_output(n_out) = 's'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      ENDIF


!----------------------------
! u vars:

    if(output_u    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'u       '
      desc_output(n_out) = 'E-W (x) velocity (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_upert.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'upert   '
      desc_output(n_out) = 'u perturbation (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_basestate.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'u0      '
      desc_output(n_out) = 'base-state u (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    IF( output_ubudget.eq.1 )THEN

      if( ud_hadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'u budget: horizontal advection (non-diff component)'
      else
        desc_output(n_out) = 'u budget: horizontal advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_vadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'u budget: vertical advection (non-diff component)'
      else
        desc_output(n_out) = 'u budget: vertical advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_hidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_hidiff'
      desc_output(n_out) = 'u budget: horiz implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_vidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_vidiff'
      desc_output(n_out) = 'u budget: vert implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_hediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_hediff'
      desc_output(n_out) = 'u budget: horiz explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_vediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_vediff'
      desc_output(n_out) = 'u budget: vert explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_hturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_hturb'
      desc_output(n_out) = 'u budget: horizontal parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_vturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_vturb'
      desc_output(n_out) = 'u budget: vertical parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_pgrad.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_pgrad'
      desc_output(n_out) = 'u budget: pressure gradient'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_rdamp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_rdamp'
      desc_output(n_out) = 'u budget: Rayleigh damper'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_cor.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_cor'
      desc_output(n_out) = 'u budget: Coriolis acceleration'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_cent.ge.1 )then
      if( axisymm.eq.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_cent'
      desc_output(n_out) = 'u budget: centrifugal acceleration'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      endif

      if( ud_pbl.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_pbl'
      desc_output(n_out) = 'u budget: PBL scheme'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( ud_subs.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'ub_subs'
      desc_output(n_out) = 'u budget: large-scale subsidence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'u'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

    ENDIF

!----------------------------
! v vars:

    if(output_v    .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'v       '
      desc_output(n_out) = 'N-S (y) velocity (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_vpert.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'vpert   '
      desc_output(n_out) = 'v perturbation (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_basestate.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'v0      '
      desc_output(n_out) = 'base-state v (grid-relative)'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    IF( output_vbudget.eq.1 )THEN

      if( vd_hadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'v budget: horizontal advection (non-diff component)'
      else
        desc_output(n_out) = 'v budget: horizontal advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_vadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'v budget: vertical advection (non-diff component)'
      else
        desc_output(n_out) = 'v budget: vertical advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_hidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_hidiff'
      desc_output(n_out) = 'v budget: horiz implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_vidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_vidiff'
      desc_output(n_out) = 'v budget: vert implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_hediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_hediff'
      desc_output(n_out) = 'v budget: horiz explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_vediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_vediff'
      desc_output(n_out) = 'v budget: vert explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_hturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_hturb'
      desc_output(n_out) = 'v budget: horizontal parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_vturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_vturb'
      desc_output(n_out) = 'v budget: vertical parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_pgrad.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_pgrad'
      desc_output(n_out) = 'v budget: pressure gradient'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_rdamp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_rdamp'
      desc_output(n_out) = 'v budget: Rayleigh damper'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_cor.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_cor'
      desc_output(n_out) = 'v budget: Coriolis acceleration'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_cent.ge.1 )then
      if( axisymm.eq.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_cent'
      desc_output(n_out) = 'v budget: centrifugal acceleration'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif
      endif

      if( vd_pbl.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_pbl'
      desc_output(n_out) = 'v budget: PBL scheme'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( vd_subs.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'vb_subs'
      desc_output(n_out) = 'v budget: large-scale subsidence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'v'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

    ENDIF

!----------------------------
! w vars:

    if(output_w  .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'w       '
      desc_output(n_out) = 'vertical velocity'
      unit_output(n_out) = 'm/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_tke.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'tke     '
      desc_output(n_out) = 'subgrid turbulence kinetic energy'
      unit_output(n_out) = 'm^2/s^2'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_km .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'kmh     '
      IF( ipbl.eq.1 )THEN
        desc_output(n_out) = 'horizontal eddy viscosity for momentum (from 2D Smagorinsky scheme)'
      ELSE
        desc_output(n_out) = 'horizontal eddy viscosity for momentum'
      ENDIF
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    if( sgsmodel.ge.1 .or. ipbl.eq.2 )then
      n_out = n_out + 1
      name_output(n_out) = 'kmv     '
      desc_output(n_out) = 'vertical eddy viscosity for momentum'
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    endif
    if(output_kh .eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'khh     '
      IF( ipbl.eq.1 )THEN
        desc_output(n_out) = 'horizontal eddy diffusivity for scalars (from 2D Smgorinsky scheme)'
      ELSE
        desc_output(n_out) = 'horizontal eddy diffusivity for scalars'
      ENDIF
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    if( sgsmodel.ge.1 .or. ipbl.eq.2 )then
      n_out = n_out + 1
      name_output(n_out) = 'khv     '
      desc_output(n_out) = 'vertical eddy diffusivity for scalars'
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    endif
    if( ipbl.eq.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'xkzh'
      desc_output(n_out) = 'eddy diffusivity for heat (from YSU)'
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'xkzq'
      desc_output(n_out) = 'eddy diffusivity for moisture (from YSU)'
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'xkzm'
      desc_output(n_out) = 'eddy viscosity (from YSU)'
      unit_output(n_out) = 'm^2/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_dissten.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'dissten '
      desc_output(n_out) = 'dissipation rate'
      unit_output(n_out) = 'm^2/s^3'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_nm.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'nm      '
      desc_output(n_out) = 'squared Brunt-Vaisala frequency'
      unit_output(n_out) = '1/s^2'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    if(output_def.eq.1)then
      n_out = n_out + 1
      name_output(n_out) = 'defv    '
      desc_output(n_out) = 'vertical deformation'
      unit_output(n_out) = '1/s^2'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      n_out = n_out + 1
      name_output(n_out) = 'defh    '
      desc_output(n_out) = 'horizontal deformation'
      unit_output(n_out) = '1/s^2'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
    endif
    IF( output_wbudget.eq.1 )THEN

      if( wd_hadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_hadv'
      if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'w budget: horizontal advection (non-diff component)'
      else
        desc_output(n_out) = 'w budget: horizontal advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_vadv.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_vadv'
      if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
        desc_output(n_out) = 'w budget: vertical advection (non-diff component)'
      else
        desc_output(n_out) = 'w budget: vertical advection'
      endif
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_hidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_hidiff'
      desc_output(n_out) = 'w budget: horiz implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_vidiff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_vidiff'
      desc_output(n_out) = 'w budget: vert implicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_hediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_hediff'
      desc_output(n_out) = 'w budget: horiz explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_vediff.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_vediff'
      desc_output(n_out) = 'w budget: vert explicit diffusion'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_hturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_hturb'
      desc_output(n_out) = 'w budget: horizontal parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_vturb.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_vturb'
      desc_output(n_out) = 'w budget: vertical parameterized turbulence'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_pgrad.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_pgrad'
      desc_output(n_out) = 'w budget: pressure gradient'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_rdamp.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_rdamp'
      desc_output(n_out) = 'w budget: Rayleigh damper'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

      if( wd_buoy.ge.1 )then
      n_out = n_out + 1
      name_output(n_out) = 'wb_buoy'
      desc_output(n_out) = 'w budget: buoyancy'
      unit_output(n_out) = 'm/s/s'
      grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
      endif

    ENDIF

      IF( pdcomp )THEN

        n_out = n_out + 1
        name_output(n_out) = 'pgradb'
        desc_output(n_out) = 'vert pres grad: buoyancy component'
        unit_output(n_out) = 'm/s/s'
        grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        n_out = n_out + 1
        name_output(n_out) = 'pgraddl'
        desc_output(n_out) = 'vert pres grad: linear dynamic component'
        unit_output(n_out) = 'm/s/s'
        grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        n_out = n_out + 1
        name_output(n_out) = 'pgraddn'
        desc_output(n_out) = 'vert pres grad: nonlinear dynamic component'
        unit_output(n_out) = 'm/s/s'
        grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts

        if( icor.eq.1 )then
        n_out = n_out + 1
        name_output(n_out) = 'pgradc'
        desc_output(n_out) = 'vert pres grad: Coriolis component'
        unit_output(n_out) = 'm/s/s'
        grid_output(n_out) = 'w'     ! s=scalar pts (3d) ; u=u pts (3d) ; v=v pts (3d) ; w=w pts (3d) ; 2=2d scalar pts
        endif

      ENDIF


!-----------------------------------------------------------------------
!  End:  define output variables:
!-----------------------------------------------------------------------

      sout2d = 0
      sout3d = 0
      u_out = 0
      v_out = 0
      w_out = 0

      do n=1,n_out
        if( grid_output(n).eq.'2' ) sout2d = sout2d+1
        if( grid_output(n).eq.'s' ) sout3d = sout3d+1
        if( grid_output(n).eq.'u' ) u_out = u_out+1
        if( grid_output(n).eq.'v' ) v_out = v_out+1
        if( grid_output(n).eq.'w' ) w_out = w_out+1
      enddo

      s_out = sout2d+sout3d

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  sout2d = ',sout2d
      if(dowr) write(outfile,*) '  sout3d = ',sout3d
      if(dowr) write(outfile,*) '  n_out  = ',n_out
      if(dowr) write(outfile,*) '  s_out  = ',s_out
      if(dowr) write(outfile,*) '  u_out  = ',u_out
      if(dowr) write(outfile,*) '  v_out  = ',v_out
      if(dowr) write(outfile,*) '  w_out  = ',w_out
      if(dowr) write(outfile,*) '  z_out  = ',z_out

      if(dowr) write(outfile,*)

!-----------------------------------------------------------------------

      if( output_format.eq.1 )then
        ! write GrADS descriptor file:
        call write_outputctl(xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,tdef,name_output,desc_output,unit_output,grid_output)
      endif

!-----------------------------------------------------------------------

      end subroutine setup_output


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine writeout(srec,urec,vrec,wrec,rtime,dt,fnum,nwrite,qname,                      &
                        name_output,desc_output,unit_output,grid_output,cmpr_output,           &
                        xh,xf,uf,yh,yf,vf,xfref,yfref,                                         &
                        rds,sigma,rdsf,sigmaf,zh,zf,mf,gx,gy,wprof,                            &
                        pi0,prs0,rho0,rr0,rf0,rrf0,th0,qv0,u0,v0,thv0,rth0,qc0,qi0,            &
                        zs,rgzu,rgzv,rain,sws,svs,sps,srs,sgs,sus,shs,thflux,qvflux,psfc,      &
                        rxh,arh1,arh2,uh,ruh,rxf,arf1,arf2,vh,rvh,mh,rmh,rmf,rr,rf,            &
                        gz,rgz,gzu,gzv,gxu,gyv,dzdx,dzdy,c1,c2,                                &
                        cd,ch,cq,tlh,f2d,prate,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,        &
                        t11,t12,t13,t22,t23,t33,rho,prs,divx,                                  &
                        rru,ua ,dumu,ugr  ,rrv,va ,dumv,vgr  ,rrw,wa ,dumw,ppi ,tha ,phi2,     &
                        sadv,thten,nm,defv,defh,dissten,                                       &
                        thpten,qvpten,qcpten,qipten,upten,vpten,xkzh,xkzq,xkzm,                &
                        lu_index,xland,mavail,tsk,tmn,tml,hml,huml,hvml,hfx,qfx,gsw,glw,tslb,  &
                        qa ,kmh,kmv,khh,khv,tkea ,swten,lwten,cldfra,                          &
                        radsw,rnflx,radswnet,radlwin,dsr,olr,pta,                              &
                        effc,effi,effs,effr,effg,effis,                                        &
                        lwupt,lwdnt,lwupb,lwdnb,                                               &
                        swupt,swdnt,swupb,swdnb,lwcf,swcf,                                     &
                        num_soil_layers,u10,v10,s10,t2,q2,znt,ust,tst,qst,u1,v1,s1,                &
                        hpbl,zol,mol,rmol,br,brcr,psim,psih,psiq,wspd,qsfc,                    &
                        dat1,dat2,dat3,reqt,dum2d          ,                                   &
                        tdiag,qdiag,udiag,vdiag,wdiag,pdiag,out2d,out3d,                       &
                        nw1,nw2,ne1,ne2,sw1,sw2,se1,se2)
                        ! end_writeout
      use input
      use constants
      use bc_module
      use comm_module
      use misclibs
      use getcape_module
      use netcdf
      use writeout_nc_module, only : disp_err,netcdf_prelim
      implicit none

      !----------------------------------------------------------
      ! This subroutine organizes writeouts for GrADS-format and
      ! netcdf-format output.
      !----------------------------------------------------------

      integer, intent(inout) :: srec,urec,vrec,wrec
      real, intent(inout) :: rtime,dt
      integer, intent(in) :: fnum,nwrite
      character(len=3), dimension(maxq), intent(in) :: qname
      character(len=60), intent(in), dimension(maxvars) :: desc_output
      character(len=40), intent(in), dimension(maxvars) :: name_output,unit_output
      character(len=1),  intent(in), dimension(maxvars) :: grid_output
      logical, intent(in), dimension(maxvars) :: cmpr_output
      real, dimension(ib:ie), intent(in) :: xh
      real, dimension(ib:ie+1), intent(in) :: xf,uf
      real, dimension(jb:je), intent(in) :: yh
      real, dimension(jb:je+1), intent(in) :: yf,vf
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, dimension(kb:ke), intent(in) :: rds,sigma
      real, dimension(kb:ke+1), intent(in) :: rdsf,sigmaf
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: zf,mf
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gx,gy
      real, intent(in), dimension(kb:ke) :: wprof
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: pi0,prs0,rho0,rr0,rf0,rrf0,th0,qv0,thv0,rth0,qc0,qi0
      real, dimension(ib:ie,jb:je), intent(in) :: zs
      real, dimension(itb:ite,jtb:jte), intent(in) :: rgzu,rgzv
      real, dimension(ib:ie,jb:je,nrain), intent(in) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, dimension(ib:ie,jb:je), intent(in) :: xland,psfc,thflux,qvflux,cd,ch,cq,tlh,f2d,prate
      real, intent(in), dimension(ib:ie) :: rxh,arh1,arh2,uh,ruh
      real, intent(in), dimension(ib:ie+1) :: rxf,arf1,arf2
      real, intent(in), dimension(jb:je) :: vh,rvh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: mh,rmh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: rmf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rr,rf
      real, intent(in), dimension(itb:ite,jtb:jte) :: gz,rgz,gzu,gzv
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gxu,gyv
      real, intent(in), dimension(itb:ite,jtb:jte) :: dzdx,dzdy
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: c1,c2
      real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: t11,t12,t13,t22,t23,t33
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: rho,prs
      real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: divx
      real, dimension(ib:ie+1,jb:je,kb:ke), intent(in) :: u0,ua
      real, dimension(ib:ie+1,jb:je,kb:ke), intent(inout) :: rru,dumu,ugr
      real, dimension(ib:ie,jb:je+1,kb:ke), intent(in) :: v0,va
      real, dimension(ib:ie,jb:je+1,kb:ke), intent(inout) :: rrv,dumv,vgr
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: wa
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(inout) :: rrw,dumw
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: ppi,tha
      real, intent(in), dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi2
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: sadv,thten
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: nm,defv,defh,dissten
      real, dimension(ibb:ieb,jbb:jeb,kbb:keb), intent(in) :: thpten,qvpten,qcpten,qipten,upten,vpten
      real, dimension(ibb:ieb,jbb:jeb,kbb:keb), intent(in) :: xkzh,xkzq,xkzm
      integer, dimension(ibl:iel,jbl:jel), intent(in) :: lu_index
      real, dimension(ib:ie,jb:je), intent(in) :: tsk
      real, dimension(ibl:iel,jbl:jel), intent(in) :: mavail,tmn,tml,hml,huml,hvml,hfx,qfx,gsw,glw
      real, dimension(ibl:iel,jbl:jel,num_soil_layers), intent(in) :: tslb
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq), intent(in) :: qa
      real, dimension(ibc:iec,jbc:jec,kbc:kec), intent(in) :: kmh,kmv,khh,khv
      real, dimension(ibt:iet,jbt:jet,kbt:ket), intent(in) :: tkea
      real, dimension(ibr:ier,jbr:jer,kbr:ker), intent(in) :: swten,lwten,cldfra
      real, dimension(ni,nj), intent(in) :: radsw,rnflx,radswnet,radlwin,dsr,olr
      real, dimension(ibp:iep,jbp:jep,kbp:kep,npt), intent(in) :: pta
      real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: effc,effi,effs,effr,effg,effis
      real, intent(inout), dimension(ibr:ier,jbr:jer) :: lwupt,lwdnt,lwupb,lwdnb
      real, intent(inout), dimension(ibr:ier,jbr:jer) :: swupt,swdnt,swupb,swdnb
      real, intent(inout), dimension(ibr:ier,jbr:jer) :: lwcf,swcf
      integer, intent(in) :: num_soil_layers
      real, dimension(ibl:iel,jbl:jel), intent(in) :: u10,v10,s10,t2,q2,hpbl,zol,mol,rmol,br,brcr,psim,psih,psiq,wspd
      real, dimension(ibl:iel,jbl:jel), intent(inout) :: qsfc
      real, dimension(ib:ie,jb:je), intent(in) :: znt,ust,tst,qst,u1,v1,s1
      real, intent(inout), dimension(ni+1,nj+1) :: dat1
      real, intent(inout), dimension(d2i,d2j) :: dat2
      real, intent(inout), dimension(d3i,d3j,d3n) :: dat3
      integer, intent(inout), dimension(d3t) :: reqt
      real, intent(inout), dimension(ib:ie,jb:je) :: dum2d
      real, intent(inout) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
      real, intent(inout) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
      real, intent(inout) , dimension(ibdp:iedp,jbdp:jedp,kbdp:kedp,npdiag) :: pdiag
      real, intent(inout) , dimension(ib2d:ie2d,jb2d:je2d,nout2d) :: out2d
      real, intent(inout) , dimension(ib3d:ie3d,jb3d:je3d,kb3d:ke3d,nout3d) :: out3d
      real, intent(inout), dimension(kmt) :: nw1,nw2,ne1,ne2,sw1,sw2,se1,se2

      integer :: i,j,k,n,nn,nmax,im,ip
      integer :: ncid,time_index,varid
      real :: tnew,pnew,thold,thnew,rdt,qv,ql,thv
      real :: tem,r1,r2,epsd,pint,plast
      character(len=8) :: text1
      logical :: opens,openu,openv,openw,foundit
      logical, parameter :: dosfcflx = .true.
      real, dimension(:), allocatable :: pfoo,tfoo,qfoo
      real :: zlcl, zlfc, zel , psource , tsource , qvsource

      if( myid.eq.0 ) print *,'  Entering writeout ... '

!--------------------------------------------------------------
!  writeout data on scalar-points

      opens = .false.
      openu = .false.
      openv = .false.
      openw = .false.

      ncid = 1
      time_index = 1

      if( myid.eq.0 ) print *,'  nwrite = ',nwrite

  IF(output_format.eq.1)THEN
  ! grads stuff:
  IF( output_filetype.eq.1 .and. myid.eq.nodemaster )THEN
    ! one output file:
    if(dowr) write(outfile,*)
    if(s_out.ge.1)then
      if(fnum.eq.51)then
        string(totlen+1:totlen+22) = '_s.dat                '
      elseif(fnum.eq.71)then
        string(totlen+1:totlen+22) = '_i.dat                '
      endif
      if(dowr) write(outfile,*) string
      open(unit=fnum,file=string,form='unformatted',access='direct',   &
           recl=(nx*ny*4),status='unknown')
      opens = .true.
    endif
    if(u_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_u.dat                '
      if(dowr) write(outfile,*) string
      open(unit=52,file=string,form='unformatted',access='direct',   &
           recl=((nx+1)*ny*4),status='unknown')
      openu = .true.
    endif
    if(v_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_v.dat                '
      if(dowr) write(outfile,*) string
      open(unit=53,file=string,form='unformatted',access='direct',   &
           recl=(nx*(ny+1)*4),status='unknown')
      openv = .true.
    endif
    if(w_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_w.dat                '
      if(dowr) write(outfile,*) string
      open(unit=54,file=string,form='unformatted',access='direct',   &
           recl=(nx*ny*4),status='unknown')
      openw = .true.
    endif
  ELSEIF( output_filetype.eq.2 .and. myid.eq.nodemaster )THEN
    ! one output file per output time:
    if(s_out.ge.1)then
      if(fnum.eq.51)then
        string(totlen+1:totlen+22) = '_XXXXXX_s.dat         '
      elseif(fnum.eq.71)then
        string(totlen+1:totlen+22) = '_XXXXXX_i.dat         '
      endif
      write(string(totlen+2:totlen+7),102) nwrite
102   format(i6.6)
      if(dowr) write(outfile,*) string
      open(unit=fnum,file=string,form='unformatted',access='direct',   &
           recl=(nx*ny*4),status='unknown')
      opens = .true.
    endif
    if(u_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_XXXXXX_u.dat         '
      write(string(totlen+2:totlen+7),102) nwrite
      if(dowr) write(outfile,*) string
      open(unit=52,file=string,form='unformatted',access='direct',   &
           recl=((nx+1)*ny*4),status='unknown')
      openu = .true.
    endif
    if(v_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_XXXXXX_v.dat         '
      write(string(totlen+2:totlen+7),102) nwrite
      if(dowr) write(outfile,*) string
      open(unit=53,file=string,form='unformatted',access='direct',   &
           recl=(nx*(ny+1)*4),status='unknown')
      openv = .true.
    endif
    if(w_out.ge.1.and.fnum.ne.71)then
      string(totlen+1:totlen+22) = '_XXXXXX_w.dat         '
      write(string(totlen+2:totlen+7),102) nwrite
      if(dowr) write(outfile,*) string
      open(unit=54,file=string,form='unformatted',access='direct',   &
           recl=(nx*ny*4),status='unknown')
      openw = .true.
    endif
  ELSEIF(output_filetype.eq.3)THEN
    ! one output file per output time AND one output file per processor:
    ! (MPI only)
    print *,'  output_filetype = ',output_filetype
    print *,'  This option is only available for MPI runs '
    print *,'  Stopping cm1 .... '
    call stopcm1
  ELSEIF(output_filetype.eq.4)THEN
    ! (MPI only)
    print *,'  output_filetype = ',output_filetype
    print *,'  This option is only available for MPI runs '
    print *,'  Stopping cm1 .... '
    call stopcm1
  ENDIF ! endif for outout_filetype
  ENDIF ! endif for output_format=1
  IF(output_format.eq.2)THEN
    ! netcdf stuff:
    opens = .false.
    if( output_filetype.eq.3 .or. myid.eq.0 )then
            call netcdf_prelim(rtime,nwrite,ncid,time_index,qname,                           &
                               name_output,desc_output,unit_output,grid_output,cmpr_output,  &
                               xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,zs,zh,zf,                &
                               dum1(ib,jb,kb),dum2(ib,jb,kb),dum3(ib,jb,kb),dum4(ib,jb,kb),  &
                               dum5(ib,jb,kb),dat2(1,1),dat2(1,2))
      opens = .true.
    endif
  ENDIF

  if(output_filetype.ge.2)then
    srec=1
    urec=1
    vrec=1
    wrec=1
  endif


      IF( imove.eq.1 )THEN
        !$omp parallel do default(shared)   &
        !$omp private(i,j,k)
        do k=1,nk
        do j=jb,je
        do i=ib,ie
          ! get ground-relative winds:
          ugr(i,j,k) = ua(i,j,k)+umove
          vgr(i,j,k) = va(i,j,k)+vmove
        enddo
        enddo
        enddo
      ELSE
        !$omp parallel do default(shared)   &
        !$omp private(i,j,k)
        do k=1,nk
        do j=jb,je
        do i=ib,ie
          ugr(i,j,k) = ua(i,j,k)
          vgr(i,j,k) = va(i,j,k)
        enddo
        enddo
        enddo
      ENDIF


    bignloop:  &
    DO n = 1 , n_out

      if( myid.eq.0 ) print *,'  n = ',n,trim(name_output(n))

    !------------------------------------------------------------------!
    !  2d variables:
    !  Place data to be written into "dum2d" array

      gridtype:  &
      IF(     grid_output(n).eq.'2' )THEN

!!!        if( myid.eq.0 ) print *,'    2d vars '

        array2d:  &
        if(     trim(name_output(n)).eq.'rain' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = rain(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'prate' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = prate(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sws' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sws(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'svs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = svs(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sps' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sps(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'srs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = srs(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sgs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sgs(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sus' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sus(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'shs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = shs(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'rain2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = rain(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sws2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sws(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'svs2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = svs(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sps2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sps(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'srs2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = srs(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sgs2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sgs(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'sus2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = sus(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'shs2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = shs(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'uh' )then

          ! get height AGL:
          if( terrain_flag )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk+1
            do j=1,nj
            do i=1,ni
              dum3(i,j,k) = zh(i,j,k)-zs(i,j)
              dumw(i,j,k) = zf(i,j,k)-zs(i,j)
            enddo
            enddo
            enddo
          else
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk+1
            do j=1,nj
            do i=1,ni
              dum3(i,j,k) = zh(i,j,k)
              dumw(i,j,k) = zf(i,j,k)
            enddo
            enddo
            enddo
          endif
          if(timestats.ge.1) time_write=time_write+mytime()
          call calcuh(uf,vf,dum3,dumw,ua,va,wa,dum1(ib,jb,1),dum2,dum5,dum6, &
                      zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf)

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cpc' )then

          if(timestats.ge.1) time_write=time_write+mytime()
          call calccpch(zh,zf,th0,qv0,dum1(ib,jb,1),dum1(ib,jb,2),tha,qa)

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cph' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'thflux' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = thflux(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvflux' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = qvflux(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tsk' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tsk(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cd' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = cd(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ch' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = ch(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cq' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = cq(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tlh' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tlh(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'f2d' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = f2d(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'psfc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = psfc(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'zs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = zs(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cref' )then

          if(timestats.ge.1) time_write=time_write+mytime()
          call calccref(dum1(ib,jb,1),qdiag(ibdq,jbdq,kbdq,qd_dbz))

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'xland' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = xland(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lu' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = float( lu_index(i,j) )
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'mavail' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = mavail(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tmn' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tmn(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'hfx' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = hfx(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qfx' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = qfx(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'gsw' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = gsw(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'glw' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = glw(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tslb1' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tslb(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tslb2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tslb(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tslb3' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tslb(i,j,3)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tslb4' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tslb(i,j,4)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tslb5' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tslb(i,j,5)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tml' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tml(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'hml' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = hml(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'huml' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = huml(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'hvml' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = hvml(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'radsw' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = radsw(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'rnflx' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = rnflx(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'radswnet' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = radswnet(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'radlwin' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = radlwin(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'olr' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = olr(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'dsr' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dsr(i,j)
          enddo
          enddo

      !c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c!
      ! begin rrtmg !

        elseif( trim(name_output(n)).eq.'lwupt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = lwupt(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwdnt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = lwdnt(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwupb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = lwupb(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwdnb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = lwdnb(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swupt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = swupt(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swdnt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = swdnt(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swupb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = swupb(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swdnb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = swdnb(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwcf' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = lwcf(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swcf' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = swcf(i,j)
          enddo
          enddo

      ! end rrtmg !
      !c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c!

        elseif( trim(name_output(n)).eq.'u10' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = u10(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'v10' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = v10(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'s10' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = s10(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'t2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = t2(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'q2' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = q2(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'znt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = znt(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ust' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = ust(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tst' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = tst(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qst' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = qst(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'hpbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = hpbl(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'zol' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = zol(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'mol' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            if( abs(rmol(i,j)).le.1.0e-10 )then
              dum2d(i,j) = sign( 1.0e10 , rmol(i,j) )
            else
              dum2d(i,j) = 1.0/rmol(i,j)
            endif
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'br' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = br(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'brcr' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = brcr(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'psim' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = psim(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'psih' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = psih(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'psiq' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = psiq(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qsfc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = qsfc(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wspd' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = wspd(i,j)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cwp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do j=1,nj
            do i=1,ni
              dum1(i,j,1) = 0.0
              dum1(i,j,2) = 0.0
              dum1(i,j,3) = 0.0
            enddo
            do k=1,nk
              if( nqc.ge.1 )then
                do i=1,ni
                  dum1(i,j,1) = dum1(i,j,1) + rho(i,j,k)*qa(i,j,k,nqc)*dz*rmh(i,j,k)
                enddo
              endif
              if( nqc.ge.1 .and. nqr.ge.1 )then
                do i=1,ni
                  dum1(i,j,2) = dum1(i,j,2) + rho(i,j,k)*(qa(i,j,k,nqc)+qa(i,j,k,nqr))*dz*rmh(i,j,k)
                enddo
              endif
              if( nqv.ge.1 )then
                do i=1,ni
                                                                                  ! 1000 kg/m3
                  dum1(i,j,3) = dum1(i,j,3) + rho(i,j,k)*qa(i,j,k,nqv)*dz*rmh(i,j,k)/1000.0
                enddo
              endif
            enddo
          enddo

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pwat' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,3)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cape' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,pfoo,tfoo,qfoo,zel,psource,tsource,qvsource)
          DO j=1,nj
          DO i=1,ni

            allocate( pfoo(nk+1) )
            allocate( tfoo(nk+1) )
            allocate( qfoo(nk+1) )

            do k=1,nk
              pfoo(k+1) = 0.01*prs(i,j,k)
              tfoo(k+1) = (th0(i,j,k)+tha(i,j,k))*(pi0(i,j,k)+ppi(i,j,k)) - 273.15
              qfoo(k+1) = qa(i,j,k,nqv)
            enddo

            pfoo(1) = cgs1*pfoo(2)+cgs2*pfoo(3)+cgs3*pfoo(4)
            tfoo(1) = cgs1*tfoo(2)+cgs2*tfoo(3)+cgs3*tfoo(4)
            qfoo(1) = cgs1*qfoo(2)+cgs2*qfoo(3)+cgs3*qfoo(4)

            ! dum1(1) = cape
            ! dum1(2) = cin
            ! dum2(1) = lcl
            ! dum2(2) = lfc

            call getcape( 3 , nk+1 , pfoo , tfoo , qfoo , dum1(i,j,1) , dum1(i,j,2) ,   &
                          dum2(i,j,1), dum2(i,j,2), zel , psource , tsource , qvsource )

            deallocate( pfoo )
            deallocate( tfoo )
            deallocate( qfoo )

          ENDDO
          ENDDO

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cin' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum1(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lcl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum2(i,j,1)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lfc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j)
          do j=1,nj
          do i=1,ni
            dum2d(i,j) = dum2(i,j,2)
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wa500' )then

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
            dum2d(i,j) = wa(i,j,k-1)+(wa(i,j,k)-wa(i,j,k-1))  &
                                    *(50000.0-plast)  &
                                    /(pint-plast)
          enddo
          enddo

        !c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c!

        else  array2d

          foundit = .false.

          ! have not found variable yet ... try out2d array:
          IF( nout2d.ge.1 )THEN

            do nn = 1,nout2d
              text1 = 'out2d   '
              if(nn.lt.10)then
                write(text1(6:6),211) nn
              elseif(nn.lt.100)then
                write(text1(6:7),212) nn
              elseif(nn.lt.1000)then
                write(text1(6:8),213) nn
              endif
              if( trim(name_output(n)).eq.trim(text1) )then
                foundit = .true.
                !$omp parallel do default(shared)  &
                !$omp private(i,j)
                do j=1,nj
                do i=1,ni
                  dum2d(i,j) = out2d(i,j,nn)
                enddo
                enddo
              endif
            enddo

          ENDIF

          ! have not found variable yet ... give up:
          IF( .not. foundit )THEN

          if(myid.eq.0) print *
          if(myid.eq.0) print *,'  unrecognized 2d variable '
          if(myid.eq.0) print *,'  n,name_output = ',n,trim(name_output(n))
          if(myid.eq.0) print *
          if(myid.eq.0) print *,'      87541 '
          call stopcm1

          ENDIF

        !c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c!

        endif  array2d

        call writeo(ni,nj,1,1,nx,ny,dum2d(ib,jb),trim(name_output(n)),          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,srec,fnum,             &
                    ncid,time_index,output_format,output_filetype,              &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,        &
                    mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)

    !------------------------------------------------------------------!
    !  s points (3d):
    !  Place data to be written into "dum1" array

      ELSEIF( grid_output(n).eq.'s' )THEN  gridtype

!!!        if( myid.eq.0 ) print *,'    s vars '

        arrays:  &
        if(     trim(name_output(n)).eq.'zh' )then

          if( fnum.eq.71 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = sigma(k)-zs(i,j)
            enddo
            enddo
            enddo
          else
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = zh(i,j,k)
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'th' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = th0(i,j,k)+tha(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'thpert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tha(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'prs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
           dum1(i,j,k) = prs(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'prspert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = prs(i,j,k)-prs0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pi' )then

          if( psolver.eq.6 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = (prs(i,j,k)*rp00)**rovcp
            enddo
            enddo
            enddo
          else
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = pi0(i,j,k)+ppi(i,j,k)
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'pipert' )then

          if( psolver.eq.6 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = (prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
            enddo
            enddo
            enddo
          else
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = ppi(i,j,k)
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'phi' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = phi2(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'rho' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = rho(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'rhopert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = rho(i,j,k)-rho0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'dbz' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_dbz)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qa(i,j,k,nqv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvpert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qa(i,j,k,nqv)-qv0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'buoyancy' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,nn)
          do k=1,maxk
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = g*tha(i,j,k)/th0(i,j,k)
            enddo
            enddo
            IF(imoist.eq.1)THEN
              do j=1,nj
              do i=1,ni
                dum1(i,j,k) = dum1(i,j,k)+g*repsm1*(qa(i,j,k,nqv)-qv0(i,j,k))
              enddo
              enddo
              do nn=nql1,nql2
                do j=1,nj
                do i=1,ni
                  dum1(i,j,k) = dum1(i,j,k)-g*qa(i,j,k,nn)
                enddo
                enddo
              enddo
              IF(iice.eq.1)THEN
              do nn=nqs1,nqs2
                do j=1,nj
                do i=1,ni
                  dum1(i,j,k) = dum1(i,j,k)-g*qa(i,j,k,nn)
                enddo
                enddo
              enddo
              ENDIF
            ENDIF
          enddo

        elseif( trim(name_output(n)).eq.'xvort' )then

          if(timestats.ge.1) time_write=time_write+mytime()
          call     calcvort(xh,xf,uf,vf,zh,mh,zf,mf,                                         &
                            zs,gz,gzu,gzv,rgz,rgzu,rgzv,gxu,gyv,rds,sigma,rdsf,sigmaf,       &
                            ugr,vgr,wa,dum2 ,dum3 ,dum4 ,dum1,dum5,dum6,dum8,dum7,th0,tha,rr,  &
                            ust,znt,u1,v1,s1)

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = dum2(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'yvort' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = dum3(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'zvort' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = dum4(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pv' )then

          if(timestats.ge.1) time_write=time_write+mytime()
          call     calcvort(xh,xf,uf,vf,zh,mh,zf,mf,                                         &
                            zs,gz,gzu,gzv,rgz,rgzu,rgzv,gxu,gyv,rds,sigma,rdsf,sigmaf,       &
                            ugr,vgr,wa,dum2 ,dum3 ,dum4 ,dum1,dum5,dum6,dum8,dum7,th0,tha,rr,  &
                            ust,znt,u1,v1,s1)

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = dum8(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'uinterp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = 0.5*(ua(i,j,k)+ua(i+1,j,k))
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vinterp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = 0.5*(va(i,j,k)+va(i,j+1,k))
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'winterp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = 0.5*(wa(i,j,k)+wa(i,j,k+1))
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pi0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pi0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'th0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = th0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'prs0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = prs0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qv0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qv0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'thpten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = thpten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvpten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qvpten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qcpten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qcpten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qipten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qipten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'upten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = upten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vpten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = vpten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'swten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = swten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'lwten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = lwten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'cldfra' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = cldfra(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'effc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effc(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'effi' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effi(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'effs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effs(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'effr' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effr(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'effg' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effg(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'effis' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = effis(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              ! convert to microns:
              dum1(i,j,k) = dum1(i,j,k)*1.0e6
            enddo
            enddo
            enddo
          endif

        elseif( trim(name_output(n)).eq.'ptb_hadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_hadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_vadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_vadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_hturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_vturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_hidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_vidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_hediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_vediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_mp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_mp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_rdamp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_rdamp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_rad' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_rad)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_div' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_div)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_diss' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_diss)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_pbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_pbl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ptb_subs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_subs)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'td_efall' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_efall)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_cond' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_cond)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_evac' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_evac)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_evar' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_evar)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_dep' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_dep)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_subl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_subl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_melt' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_melt)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tt_frz' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = tdiag(i,j,k,td_frz)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vtc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vtc)
            if( qa(i,j,k,nqc).le.qsmall ) dum1(i,j,k) = 0.0
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vtr' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vtr)
            if( qa(i,j,k,nqr).le.qsmall ) dum1(i,j,k) = 0.0
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vts' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vts)
            if( qa(i,j,k,nqs).le.qsmall ) dum1(i,j,k) = 0.0
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vtg' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vtg)
            if( qa(i,j,k,nqg).le.qsmall ) dum1(i,j,k) = 0.0
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vti' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vti)
            if( qa(i,j,k,nqi).le.qsmall ) dum1(i,j,k) = 0.0
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_hadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_hadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_vadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_hturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_hidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_hediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_vediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_mp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_mp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_pbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_pbl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qvb_subs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_subs)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qt_cond' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_cond)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qt_evac' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_evac)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qt_evar' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_evar)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qt_dep' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_dep)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'qt_subl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = qdiag(i,j,k,qd_subl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pipb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pdiag(i,j,k,1)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pipdl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pdiag(i,j,k,2)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pipdn' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pdiag(i,j,k,3)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pipc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pdiag(i,j,k,4)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vgrad' )then

          dum1 = 0.0

          do k=1,maxk
          do j=1,nj
          do i=1,ni
            qv = 0.0
            ql = 0.0
            if( imoist.eq.1 )then
              qv = qa(i,j,k,nqv)
              do nn=nql1,nql2
                ql = ql+qa(i,j,k,nn)
              enddo
              if( iice.eq.1 )then
                do nn=nqs1,nqs2
                  ql = ql+qa(i,j,k,nn)
                enddo
              endif
            endif
            thv = (th0(i,j,k)+tha(i,j,k))*(1.0+reps*qv)/(1.0+qv+ql)
            ip = min( i+1 , ni )
            im = max( i-1 , 1 )
            dum1(i,j,k) = -0.5*fcor*xh(i) + sqrt( max(0.0,               &
                                0.25*fcor*fcor*xh(i)*xh(i)               &
               +xh(i)*cp*thv*(ppi(ip,j,k)-ppi(im,j,k))/(xh(ip)-xh(im))   &
                                             ) )
          enddo
          enddo
          enddo


        !c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c-c!


        else  arrays

          foundit = .false.

          ! have not found variable yet ... try moisture:
          IF( imoist.eq.1 .and. numq.gt.1 )THEN

            do nn = 1,numq
              if( trim(name_output(n)).eq.trim(qname(nn)) )then
                foundit = .true.
                !$omp parallel do default(shared)  &
                !$omp private(i,j,k)
                do k=1,maxk
                do j=1,nj
                do i=1,ni
                  dum1(i,j,k) = qa(i,j,k,nn)
                enddo
                enddo
                enddo
              endif
            enddo

          ENDIF

          ! have not found variable yet ... try passive tracers:
          IF( iptra.eq.1 )THEN

            do nn = 1,npt
              text1='pt      '
              if(nn.le.9)then
                write(text1(3:3),155) nn
                155 format(i1.1)
              elseif(nn.le.99)then
                write(text1(3:4),154) nn
                154 format(i2.2)
              else
                write(text1(3:5),153) nn
                153 format(i3.3)
              endif
              if( trim(name_output(n)).eq.trim(text1) )then
                foundit = .true.
                !$omp parallel do default(shared)  &
                !$omp private(i,j,k)
                do k=1,maxk
                do j=1,nj
                do i=1,ni
                  dum1(i,j,k) = pta(i,j,k,nn)
                enddo
                enddo
                enddo
              endif
            enddo

          ENDIF

          ! have not found variable yet ... out3d array:
          IF( nout3d.ge.1 )THEN

            do nn = 1,nout3d
              text1 = 'out     '
              if(nn.lt.10)then
                write(text1(4:4),211) nn
211             format(i1.1)
              elseif(nn.lt.100)then
                write(text1(4:5),212) nn
212             format(i2.2)
              elseif(nn.lt.1000)then
                write(text1(4:6),213) nn
213             format(i3.3)
              elseif(nn.lt.10000)then
                write(text1(4:7),214) nn
214             format(i4.4)
              elseif(nn.lt.100000)then
                write(text1(4:8),215) nn
215             format(i5.5)
              endif
              if( trim(name_output(n)).eq.trim(text1) )then
                foundit = .true.
                !$omp parallel do default(shared)  &
                !$omp private(i,j,k)
                do k=1,maxk
                do j=1,nj
                do i=1,ni
                  dum1(i,j,k) = out3d(i,j,k,nn)
                enddo
                enddo
                enddo
              endif
            enddo

          ENDIF

          ! have not found variable yet ... give up:
          IF( .not. foundit )THEN

            if(myid.eq.0) print *
            if(myid.eq.0) print *,'  unrecognized s variable '
            if(myid.eq.0) print *,'  n,name_output = ',n,trim(name_output(n))
            if(myid.eq.0) print *
            if(myid.eq.0) print *,'      87542 '
            call stopcm1
          ENDIF

        endif  arrays

        if( fnum.eq.71 .and. trim(name_output(n)).ne.'zh' ) call zinterp(sigma,zs,zh,dum1,dum2)

        call writeo(ni,nj,1,maxk,nx,ny,dum1(ib,jb,1),trim(name_output(n)),      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,srec,fnum,             &
                    ncid,time_index,output_format,output_filetype,              &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,        &
                    mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)

    !------------------------------------------------------------------!
    !  u points (3d):
    !  Place data to be written into "dumu" array

      ELSEIF( grid_output(n).eq.'u' )THEN  gridtype
        not_interp_u:  &
        if( fnum.ne.71 )then

!!!        if( myid.eq.0 ) print *,'    u vars '

        arrayu:  &
        if(     trim(name_output(n)).eq.'u' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = ua(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'upert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = ua(i,j,k)-u0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'u0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = u0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_hadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_hadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_vadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_vadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_hturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_vturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_hidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_vidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_hediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_vediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_pgrad' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_pgrad)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_rdamp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_rdamp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_cor' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_cor)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_cent' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_cent)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_pbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_pbl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'ub_subs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni+1
            dumu(i,j,k) = udiag(i,j,k,ud_subs)
          enddo
          enddo
          enddo

        else  arrayu

          if(myid.eq.0) print *
          if(myid.eq.0) print *,'  unrecognized u variable '
          if(myid.eq.0) print *,'  n,name_output = ',n,trim(name_output(n))
          if(myid.eq.0) print *
          if(myid.eq.0) print *,'      87543 '
          call stopcm1

        endif  arrayu

        call writeo(ni+1,nj,1,maxk,nx+1,ny,dumu(ib,jb,1),trim(name_output(n)),  &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,urec,52,               &
                    ncid,time_index,output_format,output_filetype,              &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,        &
                    mynode,nodemaster,nodes,d2iu,d2ju,d3iu,d3ju)

        endif  not_interp_u
    !------------------------------------------------------------------!
    !  v points (3d):
    !  Place data to be written into "dumv" array

      ELSEIF( grid_output(n).eq.'v' )THEN  gridtype
        not_interp_v:  &
        if( fnum.ne.71 )then

!!!        if( myid.eq.0 ) print *,'    v vars '

        arrayv:  &
        if(     trim(name_output(n)).eq.'v' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = va(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vpert' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = va(i,j,k)-v0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'v0' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = v0(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_hadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_hadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_vadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_vadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_hturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_vturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_hidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_vidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_hediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_vediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_pgrad' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_pgrad)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_rdamp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_rdamp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_cor' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_cor)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_cent' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_cent)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_pbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_pbl)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'vb_subs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj+1
          do i=1,ni
            dumv(i,j,k) = vdiag(i,j,k,vd_subs)
          enddo
          enddo
          enddo

        else  arrayv

          if(myid.eq.0) print *
          if(myid.eq.0) print *,'  unrecognized v variable '
          if(myid.eq.0) print *,'  n,name_output = ',n,trim(name_output(n))
          if(myid.eq.0) print *
          if(myid.eq.0) print *,'      87544 '
          call stopcm1

        endif  arrayv

        call writeo(ni,nj+1,1,maxk,nx,ny+1,dumv(ib,jb,1),trim(name_output(n)),  &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,vrec,53,               &
                    ncid,time_index,output_format,output_filetype,              &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,        &
                    mynode,nodemaster,nodes,d2iv,d2jv,d3iv,d3jv)

        endif  not_interp_v
    !------------------------------------------------------------------!
    !  w points (3d):
    !  Place data to be written into "dumw" array

      ELSEIF( grid_output(n).eq.'w' )THEN  gridtype
        not_interp_w:  &
        if( fnum.ne.71 )then

!!!        if( myid.eq.0 ) print *,'    w vars '

        arrayw:  &
        if(     trim(name_output(n)).eq.'w' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wa(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'tke' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = tkea(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'kmh' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = kmh(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'kmv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = kmv(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'khh' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = khh(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'khv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = khv(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'xkzh' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = xkzh(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'xkzq' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = xkzq(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'xkzm' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = xkzm(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'dissten' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = dissten(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'nm' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = nm(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'defv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = defv(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'defh' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = defh(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_hadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_hadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_vadv' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_vadv)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_hturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_vturb)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_hidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_vidiff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_hediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_vediff)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_pgrad' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_pgrad)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_rdamp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_rdamp)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'wb_buoy' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk+1
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = wdiag(i,j,k,wd_buoy)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pgradb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do j=1,nj
          do i=1,ni
            dumw(i,j,1) = 0.0
            dumw(i,j,nk+1) = 0.0
          enddo
          enddo

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=2,min(nk,maxk+1)
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = -cp*(c2(i,j,k)*thv0(i,j,k)+c1(i,j,k)*thv0(i,j,k-1))  &
                             *(pdiag(i,j,k,1)-pdiag(i,j,k-1,1))*rdz*mf(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pgraddl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=2,min(nk,maxk+1)
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = -cp*(c2(i,j,k)*thv0(i,j,k)+c1(i,j,k)*thv0(i,j,k-1))  &
                             *(pdiag(i,j,k,2)-pdiag(i,j,k-1,2))*rdz*mf(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pgraddn' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=2,min(nk,maxk+1)
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = -cp*(c2(i,j,k)*thv0(i,j,k)+c1(i,j,k)*thv0(i,j,k-1))  &
                             *(pdiag(i,j,k,3)-pdiag(i,j,k-1,3))*rdz*mf(i,j,k)
          enddo
          enddo
          enddo

        elseif( trim(name_output(n)).eq.'pgradc' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=2,min(nk,maxk+1)
          do j=1,nj
          do i=1,ni
            dumw(i,j,k) = -cp*(c2(i,j,k)*thv0(i,j,k)+c1(i,j,k)*thv0(i,j,k-1))  &
                             *(pdiag(i,j,k,4)-pdiag(i,j,k-1,4))*rdz*mf(i,j,k)
          enddo
          enddo
          enddo

        else  arrayw

          if(myid.eq.0) print *
          if(myid.eq.0) print *,'  unrecognized w variable '
          if(myid.eq.0) print *,'  n,name_output = ',n,trim(name_output(n))
          if(myid.eq.0) print *
          if(myid.eq.0) print *,'      87545 '
          call stopcm1

        endif  arrayw

        call writeo(ni,nj,1,maxk+1,nx,ny,dumw(ib,jb,1),trim(name_output(n)),    &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,wrec,54,               &
                    ncid,time_index,output_format,output_filetype,              &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,        &
                    mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)

        endif  not_interp_w
    !------------------------------------------------------------------!

      ELSE  gridtype

        print *,'  Unknown setting for grid_output = ',grid_output(n)
        print *,'    67331 '
        call stopcm1

      ENDIF  gridtype

    !------------------------------------------------------------------!

    ENDDO  bignloop


!---------------------------------------------------------------
!--------------------------------------------------------------

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) 'Done Writing Data to File '
      if(dowr) write(outfile,*)

    IF(output_format.eq.1)THEN
      if( opens ) close(unit=fnum)
      if( openu ) close(unit=52)
      if( openv ) close(unit=53)
      if( openw ) close(unit=54)
    ELSEIF( output_format.eq.2 )THEN
      if( opens ) call disp_err( nf90_close(ncid) , .true. )
    ENDIF


      if( myid.eq.0 ) print *,'  ... leaving writeout '

      end subroutine writeout


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    ! writeo:
    subroutine writeo(numi,numj,numk1,numk2,nxr,nyr,var,aname,             &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,irec,fileunit,  &
                      ncid,time_index,output_format,output_filetype,       &
                      dat1,dat2,dat3,reqt,ppnode,d3n,d3t,                  &
                      mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)
    use netcdf
    use writeout_nc_module , only : write2d_nc,write3d_nc
    implicit none

    !-------------------------------------------------------------------
    ! This subroutine collects data (from other processors if this is a
    ! MPI run) and does the actual writing to disk.
    !-------------------------------------------------------------------

    integer, intent(in) :: numi,numj,numk1,numk2,nxr,nyr
    integer, intent(in) :: ppnode,d3n,d3t,d2i,d2j,d3i,d3j
    real, intent(in), dimension(1-ngxy:numi+ngxy,1-ngxy:numj+ngxy,numk1:numk2) :: var
    character(len=*), intent(in) :: aname
    integer, intent(in) :: ni,nj,ngxy,myid,numprocs,nodex,nodey,fileunit
    integer, intent(inout) :: irec,ncid
    integer, intent(in) :: time_index,output_format,output_filetype
    real, intent(inout), dimension(numi,numj) :: dat1
    real, intent(inout), dimension(d2i,d2j) :: dat2
    real, intent(inout), dimension(d3i,d3j,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(in) :: mynode,nodemaster,nodes

    integer :: i,j,k,msk
    integer :: varid,status

  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !-----------------------------------------------------------------------------
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

  IF(output_filetype.eq.1.or.output_filetype.eq.2)THEN
    ! For these two options, processor 0 writes out the entire domain:
    ! (Note:  this is the only option for single-processor runs)

    msk = 0

    kloop:  DO k=numk1,numk2

      !-------------------- non-MPI section --------------------!
!$omp parallel do default(shared)   &
!$omp private(i,j)
      do j=1,numj
      do i=1,numi
        dat2(i,j)=var(i,j,k)
      enddo
      enddo
      if( output_format.eq.2 )then
      if( k.eq.numk1 )then
        status = nf90_inq_varid(ncid,aname,varid)
        if(status.ne.nf90_noerr)then
          print *,'  Error1a in writeo, aname = ',aname
          print *,nf90_strerror(status)
          call stopcm1
        endif
      endif
      endif

      !-------------------- write data --------------------!
      IF(myid.eq.msk)THEN
        ! only processor msk writes:
        IF(output_format.eq.1)THEN
          ! ----- grads format -----
          ! normal:
          write(fileunit,rec=irec) ((dat2(i,j),i=1,nxr),j=1,nyr)
        ELSEIF(output_format.eq.2)THEN
          ! ----- netcdf format -----
          if(numk1.eq.numk2)then
            status = nf90_put_var(ncid,varid,dat2,(/1,1,time_index/),(/nxr,nyr,1/))
          else
            status = nf90_put_var(ncid,varid,dat2,(/1,1,k,time_index/),(/nxr,nyr,1,1/))
          endif
          if(status.ne.nf90_noerr)then
            print *,'  Error2 in writeo, aname = ',aname
            print *,'  ncid,varid,time_index = ',ncid,varid,time_index
            print *,nf90_strerror(status)
            call stopcm1
          endif
        ENDIF
      ENDIF
      !-------------------- end write data --------------------!

      IF( output_format.eq.1 )THEN
        irec=irec+1
!!!#ifdef MPI
!!!        msk = msk+ppnode
!!!        if( msk.ge.numprocs ) msk = msk-numprocs
!!!#endif
      ENDIF

    ENDDO  kloop


  ENDIF  ! endif for output_filetype=1,2


  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !-----   output_filetype = 3   ----------------------------------------------!
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !  this section wites one output file per MPI process:
  !  (for MPI runs only)

  IF(output_filetype.eq.3)THEN
    IF( output_format.eq.1 )THEN
      ! grads format:
      DO k=numk1,numk2
        write(fileunit,rec=irec) ((var(i,j,k),i=1,numi),j=1,numj)
        irec=irec+1
      ENDDO
    ELSEIF( output_format.eq.2 )THEN
      ! netcdf format:
      DO k=numk1,numk2
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          dat1(i,j)=var(i,j,k)
        enddo
        enddo
        if(numk1.eq.numk2)then
          call write2d_nc(aname,ncid,time_index,numi,numj,dat1(1,1))
        else
          call write3d_nc(aname,k,ncid,time_index,numi,numj,dat1(1,1))
        endif
      ENDDO
    ENDIF
  ENDIF

  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  !-----------------------------------------------------------------------------
  !ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      end subroutine writeo


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine write_outputctl(xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,tdef,name_output,desc_output,unit_output,grid_output)
      use input
      use constants , only : grads_undef
      implicit none

      real, intent(in), dimension(ib:ie) :: xh
      real, intent(in), dimension(ib:ie+1) :: xf
      real, intent(in), dimension(jb:je) :: yh
      real, intent(in), dimension(jb:je+1) :: yf
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(kb:ke+1) :: sigmaf
      character(len=15), intent(in) :: tdef
      character(len=60), intent(inout), dimension(maxvars) :: desc_output
      character(len=40), intent(inout), dimension(maxvars) :: name_output,unit_output
      character(len=1),  intent(inout), dimension(maxvars) :: grid_output

      integer :: i,j,k,n,nn,n1,n2,ctl,ctlmax
      character(len=12) :: a12
      logical :: doit

      !----------------------------------------------------------------
      ! This subroutine writes the GrADS descriptor file for 3d output
      !----------------------------------------------------------------

    idcheck:  &
    IF( myid.eq.0 )THEN

      ctlmax = 4
      if( output_interp.eq.1 ) ctlmax = 5

      ctlloop:  &
      DO ctl = 1 , ctlmax

        doit = .false.

        IF(     ctl.eq.1 )THEN
          if( s_out.ge.1 )then
          string(totlen+1:totlen+22) = '_s.ctl                '
          if(dowr) write(outfile,*) string
          if(output_filetype.eq.1)then
            sstring(baselen+1:baselen+1+12) = '_s.dat      '
          elseif(output_filetype.ge.2)then
            sstring(baselen+1:baselen+1+12) = '_00%y4_s.dat'
          endif
          doit = .true.
          endif
        ELSEIF( ctl.eq.2 )THEN
          if( u_out.ge.1 )then
          string(totlen+1:totlen+22) = '_u.ctl                '
          if(dowr) write(outfile,*) string
          if(output_filetype.eq.1)then
            sstring(baselen+1:baselen+1+12) = '_u.dat      '
          elseif(output_filetype.ge.2)then
            sstring(baselen+1:baselen+1+12) = '_00%y4_u.dat'
          endif
          doit = .true.
          endif
        ELSEIF( ctl.eq.3 )THEN
          if( v_out.ge.1 )then
          string(totlen+1:totlen+22) = '_v.ctl                '
          if(dowr) write(outfile,*) string
          if(output_filetype.eq.1)then
            sstring(baselen+1:baselen+1+12) = '_v.dat      '
          elseif(output_filetype.ge.2)then
            sstring(baselen+1:baselen+1+12) = '_00%y4_v.dat'
          endif
          doit = .true.
          endif
        ELSEIF( ctl.eq.4 )THEN
          if( w_out.ge.1 )then
          string(totlen+1:totlen+22) = '_w.ctl                '
          if(dowr) write(outfile,*) string
          if(output_filetype.eq.1)then
            sstring(baselen+1:baselen+1+12) = '_w.dat      '
          elseif(output_filetype.ge.2)then
            sstring(baselen+1:baselen+1+12) = '_00%y4_w.dat'
          endif
          doit = .true.
          endif
        ELSEIF( ctl.eq.5 )THEN
          if( s_out.ge.1 )then
          string(totlen+1:totlen+22) = '_i.ctl                '
          if(dowr) write(outfile,*) string
          if(output_filetype.eq.1)then
            sstring(baselen+1:baselen+1+12) = '_i.dat      '
          elseif(output_filetype.ge.2)then
            sstring(baselen+1:baselen+1+12) = '_00%y4_i.dat'
          endif
          doit = .true.
          endif
        ELSE
          print *,'  98371 '
          call stopcm1
        ENDIF

        dowrite:  &
        IF( doit )THEN

          open(unit=50,file=string,status='unknown')

          write(50,201) sstring
          if(output_filetype.ge.2) write(50,221)
          write(50,202)
          write(50,203) grads_undef

          IF( ctl.eq.2 )THEN
            ! u staggering:
            if(stretch_x.ge.1)then
              write(50,214) nx+1
              do i=1,nx+1
                write(50,217) 0.001*xfref(i)
              enddo
            else
              write(50,204) nx+1,0.001*xf(1),0.001*dx
            endif
          ELSE
            ! s staggering:
            if(stretch_x.ge.1)then
              write(50,214) nx
              do i=1,nx
                write(50,217) 0.001*( 0.5*(xfref(i)+xfref(i+1)) )
              enddo
            else
              write(50,204) nx,0.001*xh(1),0.001*dx
            endif
          ENDIF

          IF( ctl.eq.3 )THEN
            ! v staggering:
            if(stretch_y.ge.1)then
              write(50,215) ny+1
              do j=1,ny+1
                write(50,217) 0.001*yfref(j)
              enddo
            else
              write(50,205) ny+1,0.001*yf(1),0.001*dy
            endif
          ELSE
            ! s staggering:
            if(stretch_y.ge.1)then
              write(50,215) ny
              do j=1,ny
                write(50,217) 0.001*( 0.5*(yfref(j)+yfref(j+1)) )
              enddo
            else
              write(50,205) ny,0.001*yh(1),0.001*dy
            endif
          ENDIF

          IF( ctl.eq.4 )THEN
            ! w staggering:
            if(stretch_z.eq.0)then
              write(50,206) maxk+1,0.0,0.001*dz
            else
              write(50,216) maxk+1
              do k=1,maxk+1
                write(50,217) 0.001*sigmaf(k)
              enddo
            endif
          ELSE
            ! s staggering:
            if(stretch_z.eq.0)then
              write(50,206) maxk,0.001*sigma(1),0.001*dz
            else
              write(50,216) maxk
              do k=1,maxk
                write(50,217) 0.001*sigma(k)
              enddo
            endif
          ENDIF

          if(output_filetype.eq.1)then
            if( tapfrq.gt.1.0e-10 )then
              write(50,207) int(1+timax/tapfrq),tdef,max(1,int(tapfrq/60.0))
            else
              write(50,207) 10000,tdef,max(1,int(tapfrq/60.0))
            endif
          elseif(output_filetype.ge.2)then
            if( tapfrq.gt.1.0e-10 )then
              write(50,227) int(1+timax/tapfrq),tdef
            else
              write(50,227) 10000,tdef
            endif
          endif

          IF( ctl.eq.1 .or. ctl.eq.5 )THEN
            ! scalars:
            write(50,208) s_out
            n1 = 1
            n2 = s_out
          ELSEIF( ctl.eq.2 )THEN
            ! u vars:
            write(50,208) u_out
            n1 = s_out+1
            n2 = s_out+u_out
          ELSEIF( ctl.eq.3 )THEN
            ! v vars:
            write(50,208) v_out
            n1 = s_out+u_out+1
            n2 = s_out+u_out+v_out
          ELSEIF( ctl.eq.4 )THEN
            ! w vars:
            write(50,208) w_out
            n1 = s_out+u_out+v_out+1
            n2 = s_out+u_out+v_out+w_out
          ENDIF

          do n = n1,n2
            a12 = '            '
            nn = len(trim(unit_output(n)))
            nn = min( nn , 10 )
            write(a12(2:11),314) unit_output(n)
            write(a12(1:1),301 )       '('
            write(a12(nn+2:nn+2),301 ) ')'
            ! account for both 2d and 3d output files:
            if(     grid_output(n).eq.'2' )then
              write(50,209) name_output(n),   0  ,desc_output(n),a12
            elseif( grid_output(n).eq.'s' .or. grid_output(n).eq.'u' .or. grid_output(n).eq.'v' )then
              write(50,209) name_output(n),maxk  ,desc_output(n),a12
            elseif( grid_output(n).eq.'w' )then
              write(50,209) name_output(n),maxk+1,desc_output(n),a12
            else
              print *,'  98371 '
              call stopcm1
            endif
          enddo

          write(50,210)
          close(unit=50)

        ENDIF  dowrite

      ENDDO  ctlloop

    ENDIF  idcheck

301   format(a1)
314   format(a10)

201   format('dset ^',a70)
202   format('title cm1r19 output')
221   format('options template')
203   format('undef ',f10.1)
204   format('xdef ',i6,' linear ',f13.6,1x,f13.6)
214   format('xdef ',i6,' levels ')
205   format('ydef ',i6,' linear ',f13.6,1x,f13.6)
215   format('ydef ',i6,' levels ')
206   format('zdef ',i6,' linear ',f13.6,1x,f13.6)
216   format('zdef ',i6,' levels ')
217   format(2x,f13.6)
207   format('tdef ',i10,' linear ',a15,' ',i5,'MN')
227   format('tdef ',i10,' linear ',a15,' 1YR')
208   format('vars ',i6)
209   format(a12,1x,i6,' 99 ',a60,1x,a12)
210   format('endvars')

      end subroutine write_outputctl


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


  END MODULE writeout_module
