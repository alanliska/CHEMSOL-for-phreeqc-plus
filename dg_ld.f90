subroutine dg_ld (iterld,iprint)
  use chemsol, only : ran_shift,vatom_f
  implicit Real*8 (a-h,o-z)

  parameter (mxcenter=50)
  PARAMETER (MXATM=500)
  parameter (mxlgvn=10000)
  common /aname/ atom(mxatm),molname,ssname
  common /pctimes/ ndxp,itl,itp
  common /pcgmcntr/ pcenter(3)
  common /pcresult/ elgwa,elgvn,ebw,erelax,evdw,evqdq,ecor
  common/surf/ephil1,ephil2,ephob,fsurfa(mxcenter),evdwl(mxcenter)
  common /reg1/xw(3,mxatm),zan(mxatm),q(mxatm),rp(82),vdwc6(82), &
       n_inner,n_reg1,latom(mxatm),iacw(mxatm),rpi(mxatm), &
       q_gas(mxatm),q_mp2(mxatm)
  common /pcsav_center/ temp_center(mxcenter,3),temp_elgvn(mxcenter)
  common /vdwtds/ vdwsl,rzcut,phobsl,tdsl(mxcenter),etds,amas,tds0
  common /atom_fs/ atomfs(mxatm)

  common /pcgrid/ drg,rg,dxp0(3),rg_inner,drg_inner ! this sin will have to be rectified later
  common /scrat8/ xd(3,mxlgvn),xl(3,mxlgvn),xmua(3,mxlgvn),da(3,mxlgvn) ! another egregious sin
  character*8 atom
  character*13 molname
  character*4 ssname

  !:::  local vars
  integer i,j
  real*8 center_new(3)
  real(8) :: oshift(3*mxcenter) ! I would rather this just get passed around as a variable than 'save'd in ran_shift
  real(8) :: vatom_result(2)
  character*1 dash(72)
  data dash/72*'-'/
  !.......................................................................
  esum = 0.d0
  evqdq = 0.d0
  ecor=0.d0
  do i=1,n_reg1
     atomfs(i)=0.0d0
  end do

  !      elgvn.......noniterative lgvn energy (using distance-dependent dielectric)
  !      elgvni.....lgvn energy from the 0-th iteration
  !      elgwa......iterative lgvn energy 
  !      evqdq......solute relaxation energy calculated from PCM charges
  !      ecor.......correction for electron correlation effects         

  do i=1,ndxp
     call ran_shift(i,pcenter,center_new,temp_center,ndxp,drg,drg_inner,rg_inner,dxp0,oshift)
     !        Set grid origin for the printout of dipoles into an xmol input file.
     !        center_new(1)=0.0
     !        center_new(2)=0.0
     !        center_new(3)=0.0
     call lgvnx(center_new,elgvn,eqm,ndipole,i,iterld,iprint)
     esum = esum + elgvn

     if (iterld.eq.1) then
        call sci_lgvn(elgwa,elgvni,tds,ndipole,i)
        temp_elgvn(i)=elgwa
        tdsl(i) = tds
     else
        elgwa= 0.d0
        temp_elgvn(i)=elgvn
        tdsl(i) = 0.d0
     end if

     tdsw_a = phobsl * fsurfa(i)
     if (iprint.eq.1) then
        write(6,'(/," Averaged atomic contributions to E_phobic:",/)')
        do j=1,n_reg1
           write(6,112) j, atom(j), phobsl*atomfs(j)/float(i)
        end do
     end if
     if (iterld.eq.1) write(6,105) elgwa,evdwl(i),tdsw_a,-tds+tdsw_a
     if (iterld.eq.0) write(6,105) elgvn,evdwl(i),tdsw_a,-tds+tdsw_a
     write(6,102) dash

     !call vatom (cor,vqdq,ndipole,iterld,iprint,n_reg1,xl,xw,xmua,q,q_gas,q_mp2,slgvn,clgvn)
     vatom_result = vatom_f(ndipole,iterld,iprint,n_reg1,xl,xw,xmua,q,q_gas,q_mp2,slgvn,clgvn)
     !evqdq = evqdq + vqdq
     evqdq = evqdq + vatom_result(1)
     !ecor = ecor + cor
     ecor = ecor + vatom_result(2)
  end do

  elgvn = esum/dble(ndxp)
  evqdq = - evqdq/dble(ndxp)
  ecor  = ecor/dble(ndxp)
  call elgvn_ave(iterld,ndxp)
  call vbornx(ndipole,ebw,center_new)

  return
  !.......................................................................
102 format(1x,72a1)
105 format(/1x,'Elgvn = ',f8.3,'   Evdw = ',f8.3, &
       '   -TdS_phobic = ',f8.3,'   -TdS_total = ',f8.3,/)
112 format(i3,5x,a8,f9.3) 
end subroutine dg_ld
