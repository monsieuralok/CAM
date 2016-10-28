      subroutine modetilp(pi,imax,d,r,dndlrkny,dndlrk,
csoa     $ cat,fac,fabc,faq,kcomp,iSOA)
     $ cat,fac,fabc,faq,kcomp)

c **********************************************************************************
c     Created by Alf Kirkevåg.
c **********************************************************************************

c     This subroutine produces look-up tables of modal parameters for
c     lognormal size distrubutions with best fit to the modified size
c     distributions from the code in conteq.f.

cc 3/9-2013: Even if it is optimized w.r.t. conserving aerosol volume, the 
c     number is much better conserved (very well) than volume (not so well). 
c     Even for no added internally mixed aerosol from condensation etc. 
c     (ictot or icatot=1), estimated volume for adapted log-normal size 
c     distribution is about 6% larger than the volume before lognormal 
c     adaptation. This should be unnecessary. To begin improving the code, 
c     allow for better resolution in the r and σ grid!
cc 
cc 28/7-2014: Increased resolution (dres=sres=1.e4 instead of 1.e3) has 
c     been tested for some modes and some added concentrations), only 
c     giving much improved solutions for near zero added condensate/
c     coagulate onto the background aerosols. The original resolution has 
c     therefore been kept as it was. However, the linearly interpolated
c     dndklrny below (nlin) has now been changed with an exponentially
c     interpolated function for radii<19um, which improves the solutions
c     significantly! For ictot or icatot=1, the estimated volume for the
c     adapted log-normal size distribution is now only 1% smaller to 1% 
c     larger than the volume before lognormal adaptation.
cc     
cc 19/8-2014: After finding rks and logsks from the method above, we seek
c      a new logsks that no longer fulfills least square method requirements
c      (minimum ss), but which preserves volume (since number is already well 
c      conserved and does not change with logsks). This means that the CAM5-
c      Oslo code can be simplified (Massratio=1, no need to be calculated).
cc
cc 28/8-2014: This code is not very robust: small changes may ause the code
c      to stop working for some cases. Presently the code crashes for kcomp=8
c      when trying to find the fine solution. The coarse solution method works,
c      and has been used in this last version, but only for kcomp=8.
cc
csoa   Note tha dry lognormal the fitted size parameters do not depend
csoa   on the mass fraction fombc for kcomp=1, nor fbcbg for kcomp=4.

      implicit none

      INTEGER  i, ir, ilog, imax, j, jmin, jmax, jstep, kcomp
      INTEGER  irmin, irmax, ilogmin, ilogmax, ilog1, ilog2
      REAL     r(0:100), dndlrkny(0:100), dndlrktilp(0:100)
      REAL     rlin(20000), nlin(20000), nlintilp(20000)
      REAL     pi, d, nk, rk, rks, logsk, logsks, s, ss, 
     $         a, b, eps, nmin, nsum, nsummod, nsumtilp,  
     $         vsum, vsummod, vsumtilp, fact, logsksold  
      REAL     cat, fac, fabc, faq
      REAL     dres, invdres, sres, invsres 
      REAL     const, deltan, deltav, deltavnew
      INTEGER  j1nm, j19um, j20um, istep, isteps, jsteps
cSOA
csoa      INTEGER iSOA
cSOA
      REAL     dndlrk(0:100), nsumorig

c     Due to coarse resolution for large radii it is necessary to
c     evaluate interpolated dndlrk and dndlrktilp for linear r-grid:
c    (to avoid that small sizes get weighted more than larger sizes) 
c     Note: j=1 and 20000 corresponds to 0.001 and 20 um radius for
c     dres=1.0e3. For testing with higher resolution solutions, using
c     dres=sres=1.0e4 arrays sizes for rlin, nlin and nlintilp must
c     be increased accordingly). A key formula for understanding the
c     code below is: 
c     r(i)=10**(d(i-1)-3), where i=1,1+int(4.3/d), see constsize.f.
      dres=1.e3      ! r resolution (number of values within 1 um: only 1.e3 well tested)
      invdres=1.0/dres                ! width of each radius bin (dr)
      j20um=int(20*dres)
      j19um=int(19*dres)
      j1nm=int(0.001*dres)
c      write(*,*) 'j1nm =', j1nm
      do j=j1nm,j19um                    
        rlin(j)=invdres*j            
        i=1+int((3+log10(1.0*j)+log10(invdres))/d)
        a=(log(dndlrkny(i+1))-log(dndlrkny(i)))/(r(i+1)-r(i))
        b=(r(i+1)*log(dndlrkny(i))-r(i)
     $    *log(dndlrkny(i+1)))/(r(i+1)-r(i))
        nlin(j)=exp(a*rlin(j)+b)       ! exponentially interpolated dndklrny
c        write(888,*) i, r(i) 
c        write(887,*) j,i,a,b,nlin(j) 
c        write(*,*) rlin(j),nlin(j) 
c        write(889,*) rlin(j),nlin(j) 
      enddo
      do j=j19um+1,j20um                    
        rlin(j)=invdres*j            
        i=1+int((3+log10(1.0*j)+log10(invdres))/d)
        a=(dndlrkny(i+1)-dndlrkny(i))/(r(i+1)-r(i))
        b=dndlrkny(i)-a*r(i)  
        nlin(j)=a*rlin(j)+b           ! linearly interpolated dndklrny
c        write(888,*) i, r(i) 
c        write(887,*) j,i,a,b,nlin(j) 
c        write(*,*) rlin(j),nlin(j) 
c        write(889,*) rlin(j),nlin(j) 
      enddo
ctest
c       nlin(1)=nlin(2) ! istedet for nlin(1)=0, hadde ingen effekt på løsningen
ctest
     
c     Narrow down the search area for adapted modal radii (rks)
cc     Find smallest rlin (rmin=r(jmin)) for which nlin>1.e-4?
c     Find smallest rlin (rmin=r(jmin)) for which nlin*r**2>1.e-10?
c      eps=1.e-4
      eps=1.e-10
      nmin=1.e-10  ! initialverdi
      j=0
      do while (nmin*rlin(j)**2.lt.eps.and.j.lt.j20um)
        j=j+1        
        jmin=j
        nmin=nlin(j)
      enddo
c      write(*,*) 'rmin, nlinmin =', rlin(jmin), nlin(jmin)*rlin(jmin)**2 
cc     Find largest rlin (rmin=r(jmax)) for which nlin>1.e-4?
c     Find largest rlin (rmin=r(jmax)) for which nlin*r**2>1.e-4?
      eps=1.e-4  ! 1.e-8 gir problemer (krasj)
      nmin=1.e-10  ! initialverdi
      j=j20um
c      do while (nmin.lt.eps.and.j.gt.1)
      do while (nmin*rlin(j)**2.lt.eps.and.j.gt.j1nm)
        j=j-1        
        jmax=j
        nmin=nlin(j)
      enddo
c      write(*,*) 'rmax, nlinmax =', rlin(jmax), nlin(jmax)*rlin(jmax)**2 

c     Calculate best lognormal fitted dndlrkny, dndlrktilp: 

c     Calculate rks, logsk and deviation ss for first estimate (coarse r and logs resolution)
      sres=1.e3                       ! sigma resolution (number of values within 0-1: only 1.e3 well tested)
      invsres=1.0/sres                ! width of each sigma bin
      istep=4                         ! step value for i (istep>1 for saving some CPU time)
      ss=1.e6                         ! arbitrary large (enough) number
      ilog1=int(0.04*sres)            ! ilog for assumed low limit sigma 
      ilog2=int(0.4*sres)             ! ilog for assumed high limit sigma 
c      if(kcomp.eq.8) then
c        ilog1=1                       ! this fine SS mode may get very sharp due to large growth
c        ilog1=int(0.001*sres)          ! this fine SS mode may get very sharp due to large growth
c        ilog2=int(0.6*sres)           ! this fine SS mode may get very wide due to cloud processing
c      endif
c     logs-loop
      do ilog=ilog1,ilog2,istep
        logsk=invsres*ilog
c       r-loop
        do ir=jmin,jmax
         rk=rlin(ir)        
         jstep=int(0.05*dres*rk)+1     ! larger step values for large radii to save CPU time
         s=0.0
         do j=jmin,jmax,jstep
          nk=(1.0/logsk)*exp(-0.5*(log10(rlin(j)/rk)/logsk)**2)
          nlintilp(j)=nk/sqrt(2*pi)                 ! log-normal distribution
c          s=s+rlin(j)**4*(nlintilp(j)-nlin(j))**2  ! least squares method
          s=s+rlin(j)**2*abs(nlintilp(j)-nlin(j))   ! deviation w.r.t volume: r**2 due to linear r-axis and dN/dlogr=log10(e)*r*dN/dr
         enddo
         if(s.lt.ss) then
          ss=s 
          rks=rk
          logsks=logsk
c          write(*,*) 'rks, logsks, ss =', rks, logsks, ss
          isteps=istep
          jsteps=jstep          
         endif
        enddo  
      enddo
c      write(*,*) 'rks1, logsks1 =', rks, logsks
c     terminate if outside (on the edge of) interval     
      if(rks.le.1e-2.or.rks.ge.19e-0) then
        write(*,*) 'Error: rks.le.1e-2.or.rks.ge.19e-0'
        stop
      endif
      if(logsks.le.ilog1*invsres.or.logsks.ge.ilog2*invsres) then
        write(*,*) 'Error: logsks outside interval -> modify the code!'
        write(*,*) '(e.g. by increasing the [logmin,logmax]) range)'
        write(*,*) 'logmin,logsks,logmax =', 
     $ ilog1*invsres,logsks,ilog2*invsres
        stop
      endif

cSS      if(kcomp.eq.8) goto 123    ! this fine SS mode gets into problems with the fine resolution 
cSS      (not necessary with the new larger fine SS mode of Salter et al., 2015) 
   
c     Range of rk and logsk (*0.5 to *2) for finer resolution solution 
c      irmin=max(jmin,int(500*rks))
c      irmax=min(jmax,int(2000*rks))
c      ilogmin=max(ilog1,int(500*logsks)) 
c      ilogmax=min(ilog2,int(2000*logsks)) 
c     Range of rk and logsk) for finer resolution solution 
      irmin=max(jmin,int(dres*rks)-5*jsteps)
      irmax=min(jmax,int(dres*rks)+5*jsteps)
      ilogmin=max(ilog1,int(sres*logsks)-10*isteps) 
      ilogmax=min(ilog2,int(sres*logsks)+10*isteps) 
      if(kcomp.eq.4.or.kcomp.eq.8) then  ! special treatment for these fine modes
         irmin=1
         ilogmin=ilog1
         ilogmax=ilog2
      endif
ctest
c      if(kcomp.eq.8) then       ! special treatment for the fine SS mode
c         irmin=j1nm
c         irmax=j20um
c         ilog1=int(0.01*sres)            ! ilog for assumed low limit sigma 
c         ilog2=int(0.5*sres)             ! ilog for assumed high limit sigma 
c         ilogmin=ilog1
c         ilogmax=ilog2
c      endif
ctest
c      write(*,*) 'rmin, rmax =', irmin*invdres, irmax*invdres
c      write(*,*) 'logmin, logmax =', ilogmin*invsres, ilogmax*invsres

c     Calculate rks, logsk and deviation for final estimate
      ss=1.e6
c     logs-loop
      do ilog=ilogmin,ilogmax
        logsk=invsres*ilog
c       r-loop
        do ir=irmin,irmax
         rk=rlin(ir)        
         jstep=int(0.01*dres*rk)+1      ! larger step values for large radii to save CPU time
c         jstep=1     ! testet for kcomp=2: gir samme svar for alle pålegg 
         s=0.0
         do j=jmin,jmax,jstep
          nk=(1.0/logsk)*exp(-0.5*(log10(rlin(j)/rk)/logsk)**2)
          nlintilp(j)=nk/sqrt(2*pi)                 ! log-normal distribution
c          s=s+rlin(j)**4*(nlintilp(j)-nlin(j))**2  ! least squares method
          s=s+rlin(j)**2*abs(nlintilp(j)-nlin(j))   ! deviation w.r.t volume: r**2 due to linear r-axis and dN/dlogr=log10(e)*r*dN/dr
         enddo
         if(s.lt.ss) then
          ss=s 
          rks=rk
          logsks=logsk
c          write(*,*) 'rks, logsks, ss =', rks, logsks, ss 
          isteps=istep
          jsteps=jstep          
         endif
        enddo  
      enddo
cjfr+    beregner også ss for initialverdiene for rks og logsks:
c         rks=0.0118
c         logsks=0.2553
c         s=0.0
c         do j=jmin,jmax
c          nk=(1.0/logsks)*exp(-0.5*(log10(rlin(j)/rks)/logsks)**2)
c          nlintilp(j)=nk/sqrt(2*pi)                 ! log-normal distribution
cc          s=s+rlin(j)**4*(nlintilp(j)-nlin(j))**2  ! least squares method
c          s=s+rlin(j)**2*abs(nlintilp(j)-nlin(j))   ! deviation w.r.t volume: r**2 due to linear r-axis and dN/dlogr=log(e)*r*dN/dr
c         enddo
c         write(*,*) 'jfr. rks, logsks, ss =', rks, logsks, s
cjfr-
c      write(*,*) 'rks, logsks, ss =', rks, logsks, ss

c terminate if outside (on the edge of) interval     
      if(rks.le.irmin*invdres.or.rks.ge.irmax*invdres) then
       write(*,*) 'Error: rks outside interval -> modify the code!'
       write(*,*) '(e.g. by increasing the [rmin,rmax] range)' 
       write(*,*) 'rmin, rks, rmax =',irmin*invdres, rks,irmax*invdres  
       stop
      endif
      if(logsks.le.ilogmin*invsres.or.logsks.ge.ilogmax*invsres) then
       write(*,*) 'Error: logsks outside interval -> modify the code!'
       write(*,*) '(e.g. by increasing the [logmin,logmax]) range)'
       write(*,*) 'logmin,logsks,logmax =',
     $ ilogmin*invsres,logsks,ilogmax*invsres
       stop
      endif

c when logsks and rks are found, calculate fitted log-normal distribution
c and testing normality (integrated number = 1)**************************
c       nsum=0.0
 123   do i=j1nm,j20um
        nk=(1.0/logsks)*exp(-0.5*(log10(rlin(i)/rks)/logsks)**2)
        nlintilp(i)=nk/sqrt(2*pi)
c        write(890,*) rlin(i), max(1.e-50,nlintilp(i))
c        nsum=nsum+nlintilp(i)/rlin(i)
c        nsum=nsum+nlintilp(i)*rlin(i)**2
       enddo
c       write(*,*) 'rks, logsks, ss, nsum =', rks, logsks, ss, nsum
c       write(*,*) 'kcomp, rks, logsks =', kcomp, rks, logsks
       nsum=0.0
       vsum=0.0
       do i=1,imax
        nk=dndlrkny(i)
        vsum=vsum+nk*r(i)**3  ! volum
        nsum=nsum+nk  
       enddo
       nsummod=0.1*nsum
       vsummod=0.1*vsum
c+      alternative estimate   (gives somewhat larger deviations nsumtilp/nsummod-1)
c       vsum=0.0
c       do j=j1nm,j20um                    
c        vsum=vsum+nlin(j)*rlin(j)**3  ! w.r.t. volume (r**3 due to logarithmic r axis again)
c       enddo
c       vsummod=(invdres/d)*vsum
c- 
c       write(*,*) 'vsummod =', 0.1*vsum
       nsum=0.0
       vsum=0.0
       do i=1,imax
        nk=(1.0/logsks)*exp(-0.5*(log10(r(i)/rks)/logsks)**2)/sqrt(2*pi)
        vsum=vsum+nk*r(i)**3  ! w.r.t. volume (r**3 due to logarithmic r axis again)
        nsum=nsum+nk
       enddo
       nsumtilp=d*nsum
       vsumtilp=d*vsum
c       write(*,*) 'nsumtilp =', nsumtilp
c       write(*,*) 'nsumtilp/nsummod =', nsumtilp/nsummod
c       write(*,*) 'vsumtilp/vsummod =', vsumtilp/vsummod
c       write(*,*) 'rks, logsks =', rks, logsks
       logsksold=logsks
cc******************************************************************************
c      Recalculating logsks by assuming conserved volume and no change in rks:
c       const=2.0/(3.0*(log(10.0))**2)
c       logsks=sqrt(logsks**2-const*log(vsumtilp/vsummod)) ! overkompanserer: feil formel!?

c      Finding new logsks that no longer fulfills least square method requirements
c      (minimum ss) but which preserves volume (since number is already well conserved 
c      and does not change with logsks)
       deltav=vsumtilp/vsummod-1.0
       if(deltav.lt.0.0) then
         fact=1.001
       else
         fact=0.999
       endif
       deltavnew=deltav
       do while (deltavnew/deltav.gt.0.0) 
       logsks=logsks*fact
c       write(*,*) 'rks, logsksny=', rks, logsks

       nsum=0.0
       vsum=0.0
       do i=1,imax
        nk=(1.0/logsks)*exp(-0.5*(log10(r(i)/rks)/logsks)**2)/sqrt(2*pi)
        vsum=vsum+nk*r(i)**3  ! w.r.t. volume (r**3 due to logarithmic r axis again)
        nsum=nsum+nk
       enddo
       nsumtilp=d*nsum
       vsumtilp=d*vsum
       deltavnew=vsumtilp/vsummod-1.0
       enddo
c       write(*,*) 'nsumtilp =', nsumtilp
c       write(*,*) 'nsumtilp/nsummod mod=', nsumtilp/nsummod
c       write(*,*) 'vsumtilp/vsummod mod=', vsumtilp/vsummod
c       write(*,*) 'rks, logsksny=', rks, logsks
c       write(900,*) kcomp, rks, logsksold, logsks, nsumtilp/nsummod, 
c     $ vsumtilp/vsummod 
Ct     Compared to original size distribution
       nsum=0.0
       do i=1,imax
        nk=dndlrk(i)
        nsum=nsum+nk
       enddo
       nsumorig=d*nsum
c       write(*,*) 'nsumtilp/nsumorig =', nsumtilp/nsumorig
c       write(*,*) 'nsumtilp/nsummod  =', nsumtilp/nsummod
c       write(*,*) 'vsumtilp/vsummod =', vsumtilp/vsummod
c       write(901,*) cat, fac, fabc, faq, nsumtilp/nsumorig,
c     $ nsumtilp/nsummod, vsumtilp/vsummod 
Ct
cc******************************************************************************

c
c      Here comes the logntilp*.out look-up tables:
c
        if(kcomp.ge.1.and.kcomp.le.3) then
cSOA
csoa          if(kcomp.eq.1.and.iSOA.eq.1) then
ckcomp          write(9003,150) cat, fac, rks, logsks, kcomp
          write(9003,150) kcomp, cat, fac, rks, logsks
c          write(*,150) cat, fac, rks, logsks, kcomp
cSOA
csoa          else ! kcomp.eq.2.or.kcomp.eq.3
ckcomp          write(9003,100) cat, rks, logsks, kcomp
csoa          write(9003,100) kcomp, cat, rks, logsks
c          write(*,100) cat, rks, logsks, kcomp
csoa         endif
        elseif(kcomp.eq.4) then
ckcomp          write(9003,200) cat, fac, faq, rks, logsks, kcomp 
          write(9003,200) kcomp, cat, fac, faq, rks, logsks
c          write(*,200) cat, fac, faq, rks, logsks, kcomp 
        elseif(kcomp.ge.5.and.kcomp.le.10) then
ckcomp          write(9003,300) cat, fac, fabc, faq, rks, logsks, kcomp  
ckcomp          write(*,300) cat, fac, fabc, faq, rks, logsks, kcomp  
          write(9003,300) kcomp, cat, fac, fabc, faq, rks, logsks
          write(*,300) kcomp, cat, fac, fabc, faq, rks, logsks
        else
          write(*,*) 'Only calculations for modes 1-10 are necessary'
          stop
        endif

ckcomp 100  format(3(x,e12.5),x,I3)
ckcomp 150  format(4(x,e12.5),x,I3)
ckcomp 200  format(5(x,e12.5),x,I3)
ckcomp 300  format(6(x,e12.5),x,I3)
 100  format(I3,3(x,e12.5))
 150  format(I3,4(x,e12.5))
 200  format(I3,5(x,e12.5))
 300  format(I3,6(x,e12.5))

      return
      end

