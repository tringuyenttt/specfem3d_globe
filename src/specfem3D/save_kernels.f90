!=====================================================================
!
!          S p e c f e m 3 D  G l o b e  V e r s i o n  5 . 1
!          --------------------------------------------------
!
!          Main authors: Dimitri Komatitsch and Jeroen Tromp
!                        Princeton University, USA
!             and CNRS / INRIA / University of Pau, France
! (c) Princeton University and CNRS / INRIA / University of Pau
!                            April 2011
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 2 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
!=====================================================================

  subroutine save_kernels_crust_mantle(myrank,scale_t,scale_displ, &
                  cijkl_kl_crust_mantle,rho_kl_crust_mantle, &
                  alpha_kl_crust_mantle,beta_kl_crust_mantle, &
                  mu_kl_crust_mantle, kappa_kl_crust_mantle, rhonotprime_kl_crust_mantle, &
                  ystore_crust_mantle,zstore_crust_mantle, &
                  rhostore_crust_mantle,muvstore_crust_mantle, &
                  kappavstore_crust_mantle,ibool_crust_mantle, &
                  kappahstore_crust_mantle,muhstore_crust_mantle, &
                  eta_anisostore_crust_mantle,ispec_is_tiso_crust_mantle, &
                  LOCAL_PATH,ANISOTROPIC_KL,SAVE_TRANSVERSE_KL)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer myrank

  double precision :: scale_t,scale_displ

  real(kind=CUSTOM_REAL), dimension(21,NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT) :: &
    cijkl_kl_crust_mantle

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT) :: &
    rho_kl_crust_mantle, beta_kl_crust_mantle, alpha_kl_crust_mantle

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT) :: &
    mu_kl_crust_mantle, kappa_kl_crust_mantle, rhonotprime_kl_crust_mantle

  real(kind=CUSTOM_REAL), dimension(NGLOB_CRUST_MANTLE) :: &
        ystore_crust_mantle,zstore_crust_mantle

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPECMAX_ISO_MANTLE) :: &
        rhostore_crust_mantle,kappavstore_crust_mantle,muvstore_crust_mantle

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPECMAX_TISO_MANTLE) :: &
        kappahstore_crust_mantle,muhstore_crust_mantle,eta_anisostore_crust_mantle

  logical, dimension(NSPEC_CRUST_MANTLE) :: ispec_is_tiso_crust_mantle

  integer, dimension(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE) :: ibool_crust_mantle

  character(len=150) LOCAL_PATH

  ! local parameters
  real(kind=CUSTOM_REAL),dimension(21) ::  cijkl_kl_local
  real(kind=CUSTOM_REAL) :: scale_kl,scale_kl_ani,scale_kl_rho
  real(kind=CUSTOM_REAL) :: rhol,mul,kappal,rho_kl,alpha_kl,beta_kl
  integer :: ispec,i,j,k,iglob
  character(len=150) prname
  logical :: ANISOTROPIC_KL,SAVE_TRANSVERSE_KL

  ! transverse isotropic parameters
  real(kind=CUSTOM_REAL), dimension(21) :: an_kl
  real(kind=CUSTOM_REAL), dimension(:,:,:,:),allocatable :: &
    alphav_kl_crust_mantle,alphah_kl_crust_mantle, &
    betav_kl_crust_mantle,betah_kl_crust_mantle, &
    eta_kl_crust_mantle

  ! bulk parameterization
  real(kind=CUSTOM_REAL), dimension(:,:,:,:),allocatable :: &
    bulk_c_kl_crust_mantle,bulk_beta_kl_crust_mantle, &
    bulk_betav_kl_crust_mantle,bulk_betah_kl_crust_mantle
  real(kind=CUSTOM_REAL) :: A,C,F,L,N,eta
  real(kind=CUSTOM_REAL) :: muvl,kappavl,muhl,kappahl
  real(kind=CUSTOM_REAL) :: alphav_sq,alphah_sq,betav_sq,betah_sq,bulk_sq

  ! scaling factors
  scale_kl = scale_t/scale_displ * 1.d9
  ! For anisotropic kernels
  ! final unit : [s km^(-3) GPa^(-1)]
  scale_kl_ani = scale_t**3 / (RHOAV*R_EARTH**3) * 1.d18
  ! final unit : [s km^(-3) (kg/m^3)^(-1)]
  scale_kl_rho = scale_t / scale_displ / RHOAV * 1.d9

  ! allocates temporary arrays
  if( SAVE_TRANSVERSE_KL ) then
    ! transverse isotropic kernel arrays for file output
    allocate(alphav_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            alphah_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            betav_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            betah_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            eta_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT))

    ! isotropic kernel arrays for file output
    allocate(bulk_c_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            bulk_betav_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            bulk_betah_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            bulk_beta_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT))
  endif

  if( .not. ANISOTROPIC_KL ) then
    ! allocates temporary isotropic kernel arrays for file output
    allocate(bulk_c_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT), &
            bulk_beta_kl_crust_mantle(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT))
  endif

  ! crust_mantle
  do ispec = 1, NSPEC_CRUST_MANTLE
    do k = 1, NGLLZ
      do j = 1, NGLLY
        do i = 1, NGLLX

          if (ANISOTROPIC_KL) then

            ! For anisotropic kernels
            iglob = ibool_crust_mantle(i,j,k,ispec)

            ! The cartesian global cijkl_kl are rotated into the spherical local cijkl_kl
            ! ystore and zstore are thetaval and phival (line 2252) -- dangerous
            call rotate_kernels_dble(cijkl_kl_crust_mantle(:,i,j,k,ispec),cijkl_kl_local, &
                 ystore_crust_mantle(iglob),zstore_crust_mantle(iglob))

            cijkl_kl_crust_mantle(:,i,j,k,ispec) = cijkl_kl_local * scale_kl_ani
            rho_kl_crust_mantle(i,j,k,ispec) = rho_kl_crust_mantle(i,j,k,ispec) * scale_kl_rho

            ! transverse isotropic kernel calculations
            if( SAVE_TRANSVERSE_KL ) then
              ! note: transverse isotropic kernels are calculated for all elements
              !
              !          however, the factors A,C,L,N,F are based only on transverse elements
              !          in between Moho and 220 km layer, otherwise they are taken from isotropic values

              rhol = rhostore_crust_mantle(i,j,k,ispec)

              ! transverse isotropic parameters from compute_force_crust_mantle.f90
              ! C=rhovpvsq A=rhovphsq L=rhovsvsq N=rhovshsq eta=F/(A - 2 L)

              ! Get A,C,F,L,N,eta from kappa,mu
              ! element can have transverse isotropy if between d220 and Moho
              if( .not. ispec_is_tiso_crust_mantle(ispec) ) then

                ! layer with no transverse isotropy
                ! A,C,L,N,F from isotropic model

                mul = muvstore_crust_mantle(i,j,k,ispec)
                kappal = kappavstore_crust_mantle(i,j,k,ispec)
                muvl = mul
                muhl = mul
                kappavl = kappal
                kappahl = kappal

                A = kappal + FOUR_THIRDS * mul
                C = A
                L = mul
                N = mul
                F = kappal - 2._CUSTOM_REAL/3._CUSTOM_REAL * mul
                eta = 1._CUSTOM_REAL

              else

                ! A,C,L,N,F from transverse isotropic model
                kappavl = kappavstore_crust_mantle(i,j,k,ispec)
                kappahl = kappahstore_crust_mantle(i,j,k,ispec)
                muvl = muvstore_crust_mantle(i,j,k,ispec)
                muhl = muhstore_crust_mantle(i,j,k,ispec)
                kappal = kappavl

                A = kappahl + FOUR_THIRDS * muhl
                C = kappavl + FOUR_THIRDS * muvl
                L = muvl
                N = muhl
                eta = eta_anisostore_crust_mantle(i,j,k,ispec)  ! that is  F / (A - 2 L)
                F = eta * ( A - 2._CUSTOM_REAL * L )

              endif

              ! note: cijkl_kl_local() is fully anisotropic C_ij kernel components (non-dimensionalized)
              !          for GLL point at (i,j,k,ispec)

              ! Purpose : compute the kernels for the An coeffs (an_kl)
              ! from the kernels for Cij (cijkl_kl_local)
              ! At r,theta,phi fixed
              ! kernel def : dx = kij * dcij + krho * drho
              !                = kAn * dAn  + krho * drho

              ! Definition of the input array cij_kl :
              ! cij_kl(1) = C11 ; cij_kl(2) = C12 ; cij_kl(3) = C13
              ! cij_kl(4) = C14 ; cij_kl(5) = C15 ; cij_kl(6) = C16
              ! cij_kl(7) = C22 ; cij_kl(8) = C23 ; cij_kl(9) = C24
              ! cij_kl(10) = C25 ; cij_kl(11) = C26 ; cij_kl(12) = C33
              ! cij_kl(13) = C34 ; cij_kl(14) = C35 ; cij_kl(15) = C36
              ! cij_kl(16) = C44 ; cij_kl(17) = C45 ; cij_kl(18) = C46
              ! cij_kl(19) = C55 ; cij_kl(20) = C56 ; cij_kl(21) = C66
              ! where the Cij (Voigt's notation) are defined as function of
              ! the components of the elastic tensor in spherical coordinates
              ! by eq. (A.1) of Chen & Tromp, GJI 168 (2007)

              ! From the relations giving Cij in function of An
              ! Checked with Min Chen's results (routine build_cij)

              an_kl(1) = cijkl_kl_local(1)+cijkl_kl_local(2)+cijkl_kl_local(7)  !A
              an_kl(2) = cijkl_kl_local(12)                                     !C
              an_kl(3) = -2*cijkl_kl_local(2)+cijkl_kl_local(21)                !N
              an_kl(4) = cijkl_kl_local(16)+cijkl_kl_local(19)                  !L
              an_kl(5) = cijkl_kl_local(3)+cijkl_kl_local(8)                    !F

              ! not used yet
              !an_kl(6)=2*cijkl_kl_local(5)+2*cijkl_kl_local(10)+2*cijkl_kl_local(14)          !Jc
              !an_kl(7)=2*cijkl_kl_local(4)+2*cijkl_kl_local(9)+2*cijkl_kl_local(13)           !Js
              !an_kl(8)=-2*cijkl_kl_local(14)                                  !Kc
              !an_kl(9)=-2*cijkl_kl_local(13)                                  !Ks
              !an_kl(10)=-2*cijkl_kl_local(10)+cijkl_kl_local(18)                      !Mc
              !an_kl(11)=2*cijkl_kl_local(4)-cijkl_kl_local(20)                        !Ms
              !an_kl(12)=cijkl_kl_local(1)-cijkl_kl_local(7)                           !Bc
              !an_kl(13)=-1./2.*(cijkl_kl_local(6)+cijkl_kl_local(11))                 !Bs
              !an_kl(14)=cijkl_kl_local(3)-cijkl_kl_local(8)                           !Hc
              !an_kl(15)=-cijkl_kl_local(15)                                   !Hs
              !an_kl(16)=-cijkl_kl_local(16)+cijkl_kl_local(19)                        !Gc
              !an_kl(17)=-cijkl_kl_local(17)                                   !Gs
              !an_kl(18)=cijkl_kl_local(5)-cijkl_kl_local(10)-cijkl_kl_local(18)               !Dc
              !an_kl(19)=cijkl_kl_local(4)-cijkl_kl_local(9)+cijkl_kl_local(20)                !Ds
              !an_kl(20)=cijkl_kl_local(1)-cijkl_kl_local(2)+cijkl_kl_local(7)-cijkl_kl_local(21)      !Ec
              !an_kl(21)=-cijkl_kl_local(6)+cijkl_kl_local(11)                         !Es

              ! K_rho (primary kernel, for a parameterization (A,C,L,N,F,rho) )
              rhonotprime_kl_crust_mantle(i,j,k,ispec) = rhol * rho_kl_crust_mantle(i,j,k,ispec) / scale_kl_rho

              ! note: transverse isotropic kernels are calculated for ALL elements,
              !          and not just transverse elements
              !
              ! note: the kernels are for relative perturbations (delta ln (m_i) = (m_i - m_0)/m_i )
              !
              ! Gets transverse isotropic kernels
              ! (see Appendix B of Sieminski et al., GJI 171, 2007)

              ! for parameterization: ( alpha_v, alpha_h, beta_v, beta_h, eta, rho )
              ! K_alpha_v
              alphav_kl_crust_mantle(i,j,k,ispec) = 2*C*an_kl(2)
              ! K_alpha_h
              alphah_kl_crust_mantle(i,j,k,ispec) = 2*A*an_kl(1) + 2*A*eta*an_kl(5)
              ! K_beta_v
              betav_kl_crust_mantle(i,j,k,ispec) = 2*L*an_kl(4) - 4*L*eta*an_kl(5)
              ! K_beta_h
              betah_kl_crust_mantle(i,j,k,ispec) = 2*N*an_kl(3)
              ! K_eta
              eta_kl_crust_mantle(i,j,k,ispec) = F*an_kl(5)
              ! K_rhoprime  (for a parameterization (alpha_v, ..., rho) )
              rho_kl_crust_mantle(i,j,k,ispec) = A*an_kl(1) + C*an_kl(2) &
                                              + N*an_kl(3) + L*an_kl(4) + F*an_kl(5) &
                                              + rhonotprime_kl_crust_mantle(i,j,k,ispec)

              ! write the kernel in physical units
              rhonotprime_kl_crust_mantle(i,j,k,ispec) = - rhonotprime_kl_crust_mantle(i,j,k,ispec) * scale_kl

              alphav_kl_crust_mantle(i,j,k,ispec) = - alphav_kl_crust_mantle(i,j,k,ispec) * scale_kl
              alphah_kl_crust_mantle(i,j,k,ispec) = - alphah_kl_crust_mantle(i,j,k,ispec) * scale_kl
              betav_kl_crust_mantle(i,j,k,ispec) = - betav_kl_crust_mantle(i,j,k,ispec) * scale_kl
              betah_kl_crust_mantle(i,j,k,ispec) = - betah_kl_crust_mantle(i,j,k,ispec) * scale_kl
              eta_kl_crust_mantle(i,j,k,ispec) = - eta_kl_crust_mantle(i,j,k,ispec) * scale_kl
              rho_kl_crust_mantle(i,j,k,ispec) = - rho_kl_crust_mantle(i,j,k,ispec) * scale_kl

              ! for parameterization: ( bulk, beta_v, beta_h, eta, rho )
              ! where kappa_v = kappa_h = kappa and bulk c = sqrt( kappa / rho )
              betav_sq = muvl / rhol
              betah_sq = muhl / rhol
              alphav_sq = ( kappal + FOUR_THIRDS * muvl ) / rhol
              alphah_sq = ( kappal + FOUR_THIRDS * muhl ) / rhol
              bulk_sq = kappal / rhol

              bulk_c_kl_crust_mantle(i,j,k,ispec) = &
                bulk_sq / alphav_sq * alphav_kl_crust_mantle(i,j,k,ispec) + &
                bulk_sq / alphah_sq * alphah_kl_crust_mantle(i,j,k,ispec)

              bulk_betah_kl_crust_mantle(i,j,k,ispec ) = &
                betah_kl_crust_mantle(i,j,k,ispec) + &
                FOUR_THIRDS * betah_sq / alphah_sq * alphah_kl_crust_mantle(i,j,k,ispec)

              bulk_betav_kl_crust_mantle(i,j,k,ispec ) = &
                betav_kl_crust_mantle(i,j,k,ispec) + &
                FOUR_THIRDS * betav_sq / alphav_sq * alphav_kl_crust_mantle(i,j,k,ispec)
              ! the rest, K_eta and K_rho are the same as above

              ! to check: isotropic kernels from transverse isotropic ones
              alpha_kl_crust_mantle(i,j,k,ispec) = alphav_kl_crust_mantle(i,j,k,ispec) &
                                                  + alphah_kl_crust_mantle(i,j,k,ispec)
              beta_kl_crust_mantle(i,j,k,ispec) = betav_kl_crust_mantle(i,j,k,ispec) &
                                                  + betah_kl_crust_mantle(i,j,k,ispec)
              !rho_kl_crust_mantle(i,j,k,ispec) = rhonotprime_kl_crust_mantle(i,j,k,ispec) &
              !                                    + alpha_kl_crust_mantle(i,j,k,ispec) &
              !                                    + beta_kl_crust_mantle(i,j,k,ispec)
              bulk_beta_kl_crust_mantle(i,j,k,ispec) = bulk_betah_kl_crust_mantle(i,j,k,ispec ) &
                                                    + bulk_betav_kl_crust_mantle(i,j,k,ispec )

            endif ! SAVE_TRANSVERSE_KL

          else

            ! isotropic kernels

            rhol = rhostore_crust_mantle(i,j,k,ispec)
            mul = muvstore_crust_mantle(i,j,k,ispec)
            kappal = kappavstore_crust_mantle(i,j,k,ispec)

            ! kernel values for rho, kappa, mu (primary kernel values)
            rho_kl = - rhol * rho_kl_crust_mantle(i,j,k,ispec)
            alpha_kl = - kappal * alpha_kl_crust_mantle(i,j,k,ispec) ! note: alpha_kl corresponds to K_kappa
            beta_kl =  - 2 * mul * beta_kl_crust_mantle(i,j,k,ispec) ! note: beta_kl corresponds to K_mu

            ! for a parameterization: (rho,mu,kappa) "primary" kernels
            rhonotprime_kl_crust_mantle(i,j,k,ispec) = rho_kl * scale_kl
            mu_kl_crust_mantle(i,j,k,ispec) = beta_kl * scale_kl
            kappa_kl_crust_mantle(i,j,k,ispec) = alpha_kl * scale_kl

            ! for a parameterization: (rho,alpha,beta)
            ! kernels rho^prime, beta, alpha
            rho_kl_crust_mantle(i,j,k,ispec) = (rho_kl + alpha_kl + beta_kl) * scale_kl
            beta_kl_crust_mantle(i,j,k,ispec) = &
              2._CUSTOM_REAL * (beta_kl - FOUR_THIRDS * mul * alpha_kl / kappal) * scale_kl
            alpha_kl_crust_mantle(i,j,k,ispec) = &
              2._CUSTOM_REAL * (1 +  FOUR_THIRDS * mul / kappal) * alpha_kl * scale_kl

            ! for a parameterization: (rho,bulk, beta)
            ! where bulk wave speed is c = sqrt( kappa / rho)
            ! note: rhoprime is the same as for (rho,alpha,beta) parameterization
            bulk_c_kl_crust_mantle(i,j,k,ispec) = 2._CUSTOM_REAL * alpha_kl * scale_kl
            bulk_beta_kl_crust_mantle(i,j,k,ispec ) = 2._CUSTOM_REAL * beta_kl * scale_kl

          endif

        enddo
      enddo
    enddo
  enddo

  call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

  ! For anisotropic kernels
  if (ANISOTROPIC_KL) then

    ! outputs transverse isotropic kernels only
    if( SAVE_TRANSVERSE_KL ) then
      ! transverse isotropic kernels
      ! (alpha_v, alpha_h, beta_v, beta_h, eta, rho ) parameterization
      open(unit=27,file=trim(prname)//'alphav_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) alphav_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'alphah_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) alphah_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'betav_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) betav_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'betah_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) betah_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'eta_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) eta_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'rho_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) rho_kl_crust_mantle
      close(27)

      ! in case one is interested in primary kernel K_rho
      !open(unit=27,file=trim(prname)//'rhonotprime_kernel.bin',status='unknown',form='unformatted',action='write')
      !write(27) rhonotprime_kl_crust_mantle
      !close(27)

      ! (bulk, beta_v, beta_h, eta, rho ) parameterization: K_eta and K_rho same as above
      open(unit=27,file=trim(prname)//'bulk_c_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) bulk_c_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'bulk_betav_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) bulk_betav_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'bulk_betah_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) bulk_betah_kl_crust_mantle
      close(27)

      ! to check: isotropic kernels
      open(unit=27,file=trim(prname)//'alpha_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) alpha_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'beta_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) beta_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'bulk_beta_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) bulk_beta_kl_crust_mantle
      close(27)

    else

      ! fully anisotropic kernels
      ! note: the C_ij and density kernels are not for relative perturbations (delta ln( m_i) = delta m_i / m_i),
      !          but absolute perturbations (delta m_i = m_i - m_0)
      open(unit=27,file=trim(prname)//'rho_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) - rho_kl_crust_mantle
      close(27)
      open(unit=27,file=trim(prname)//'cijkl_kernel.bin',status='unknown',form='unformatted',action='write')
      write(27) - cijkl_kl_crust_mantle
      close(27)

    endif

  else
    ! primary kernels: (rho,kappa,mu) parameterization
    open(unit=27,file=trim(prname)//'rhonotprime_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) rhonotprime_kl_crust_mantle
    close(27)
    open(unit=27,file=trim(prname)//'kappa_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) kappa_kl_crust_mantle
    close(27)
    open(unit=27,file=trim(prname)//'mu_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) mu_kl_crust_mantle
    close(27)

    ! (rho, alpha, beta ) parameterization
    open(unit=27,file=trim(prname)//'rho_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) rho_kl_crust_mantle
    close(27)
    open(unit=27,file=trim(prname)//'alpha_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) alpha_kl_crust_mantle
    close(27)
    open(unit=27,file=trim(prname)//'beta_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) beta_kl_crust_mantle
    close(27)

    ! (rho, bulk, beta ) parameterization, K_rho same as above
    open(unit=27,file=trim(prname)//'bulk_c_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) bulk_c_kl_crust_mantle
    close(27)
    open(unit=27,file=trim(prname)//'bulk_beta_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) bulk_beta_kl_crust_mantle
    close(27)


  endif

  ! cleans up temporary kernel arrays
  if( SAVE_TRANSVERSE_KL ) then
    deallocate(alphav_kl_crust_mantle,alphah_kl_crust_mantle, &
        betav_kl_crust_mantle,betah_kl_crust_mantle, &
        eta_kl_crust_mantle)
    deallocate(bulk_c_kl_crust_mantle,bulk_betah_kl_crust_mantle, &
        bulk_betav_kl_crust_mantle,bulk_beta_kl_crust_mantle)
  endif
  if( .not. ANISOTROPIC_KL ) then
    deallocate(bulk_c_kl_crust_mantle,bulk_beta_kl_crust_mantle)
  endif

  end subroutine save_kernels_crust_mantle

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_outer_core(myrank,scale_t,scale_displ, &
                        rho_kl_outer_core,alpha_kl_outer_core, &
                        rhostore_outer_core,kappavstore_outer_core, &
                        LOCAL_PATH)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer myrank

  double precision :: scale_t,scale_displ

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_OUTER_CORE_ADJOINT) :: &
    rho_kl_outer_core,alpha_kl_outer_core

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_OUTER_CORE) :: &
        rhostore_outer_core,kappavstore_outer_core

  character(len=150) LOCAL_PATH

  ! local parameters
  real(kind=CUSTOM_REAL):: scale_kl
  real(kind=CUSTOM_REAL) :: rhol,kappal,rho_kl,alpha_kl
  integer :: ispec,i,j,k
  character(len=150) prname

  scale_kl = scale_t/scale_displ * 1.d9

  ! outer_core
  do ispec = 1, NSPEC_OUTER_CORE
    do k = 1, NGLLZ
      do j = 1, NGLLY
        do i = 1, NGLLX
          rhol = rhostore_outer_core(i,j,k,ispec)
          kappal = kappavstore_outer_core(i,j,k,ispec)
          rho_kl = - rhol * rho_kl_outer_core(i,j,k,ispec)
          alpha_kl = - kappal * alpha_kl_outer_core(i,j,k,ispec)

          rho_kl_outer_core(i,j,k,ispec) = (rho_kl + alpha_kl) * scale_kl
          alpha_kl_outer_core(i,j,k,ispec) = 2 * alpha_kl * scale_kl
        enddo
      enddo
    enddo
  enddo

  call create_name_database(prname,myrank,IREGION_OUTER_CORE,LOCAL_PATH)

  open(unit=27,file=trim(prname)//'rho_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) rho_kl_outer_core
  close(27)
  open(unit=27,file=trim(prname)//'alpha_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) alpha_kl_outer_core
  close(27)

  end subroutine save_kernels_outer_core

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_inner_core(myrank,scale_t,scale_displ, &
                          rho_kl_inner_core,beta_kl_inner_core,alpha_kl_inner_core, &
                          rhostore_inner_core,muvstore_inner_core,kappavstore_inner_core, &
                          LOCAL_PATH)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer myrank

  double precision :: scale_t,scale_displ

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_INNER_CORE_ADJOINT) :: &
    rho_kl_inner_core, beta_kl_inner_core, alpha_kl_inner_core

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_INNER_CORE) :: &
        rhostore_inner_core, kappavstore_inner_core,muvstore_inner_core

  character(len=150) LOCAL_PATH

  ! local parameters
  real(kind=CUSTOM_REAL):: scale_kl
  real(kind=CUSTOM_REAL) :: rhol,mul,kappal,rho_kl,alpha_kl,beta_kl
  integer :: ispec,i,j,k
  character(len=150) prname

  scale_kl = scale_t/scale_displ * 1.d9

  ! inner_core
  do ispec = 1, NSPEC_INNER_CORE
    do k = 1, NGLLZ
      do j = 1, NGLLY
        do i = 1, NGLLX
          rhol = rhostore_inner_core(i,j,k,ispec)
          mul = muvstore_inner_core(i,j,k,ispec)
          kappal = kappavstore_inner_core(i,j,k,ispec)

          rho_kl = -rhol * rho_kl_inner_core(i,j,k,ispec)
          alpha_kl = -kappal * alpha_kl_inner_core(i,j,k,ispec)
          beta_kl =  - 2 * mul * beta_kl_inner_core(i,j,k,ispec)

          rho_kl_inner_core(i,j,k,ispec) = (rho_kl + alpha_kl + beta_kl) * scale_kl
          beta_kl_inner_core(i,j,k,ispec) = 2 * (beta_kl - FOUR_THIRDS * mul * alpha_kl / kappal) * scale_kl
          alpha_kl_inner_core(i,j,k,ispec) = 2 * (1 +  FOUR_THIRDS * mul / kappal) * alpha_kl * scale_kl
        enddo
      enddo
    enddo
  enddo

  call create_name_database(prname,myrank,IREGION_INNER_CORE,LOCAL_PATH)

  open(unit=27,file=trim(prname)//'rho_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) rho_kl_inner_core
  close(27)
  open(unit=27,file=trim(prname)//'alpha_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) alpha_kl_inner_core
  close(27)
  open(unit=27,file=trim(prname)//'beta_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) beta_kl_inner_core
  close(27)

  end subroutine save_kernels_inner_core

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_boundary_kl(myrank,scale_t,scale_displ, &
                                  moho_kl,d400_kl,d670_kl,cmb_kl,icb_kl, &
                                  LOCAL_PATH,HONOR_1D_SPHERICAL_MOHO)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer myrank

  double precision :: scale_t,scale_displ

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NSPEC2D_MOHO) :: moho_kl
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NSPEC2D_400) :: d400_kl
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NSPEC2D_670) :: d670_kl
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NSPEC2D_CMB) :: cmb_kl
  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NSPEC2D_ICB) :: icb_kl

  character(len=150) LOCAL_PATH

  logical HONOR_1D_SPHERICAL_MOHO

  ! local parameters
  real(kind=CUSTOM_REAL):: scale_kl
  character(len=150) prname

  scale_kl = scale_t/scale_displ * 1.d9

  ! scale the boundary kernels properly: *scale_kl gives s/km^3 and 1.d3 gives
  ! the relative boundary kernels (for every 1 km) in s/km^2
  moho_kl = moho_kl * scale_kl * 1.d3
  d400_kl = d400_kl * scale_kl * 1.d3
  d670_kl = d670_kl * scale_kl * 1.d3
  cmb_kl = cmb_kl * scale_kl * 1.d3
  icb_kl = icb_kl * scale_kl * 1.d3

  call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

  if (.not. SUPPRESS_CRUSTAL_MESH .and. HONOR_1D_SPHERICAL_MOHO) then
    open(unit=27,file=trim(prname)//'moho_kernel.bin',status='unknown',form='unformatted',action='write')
    write(27) moho_kl
    close(27)
  endif

  open(unit=27,file=trim(prname)//'d400_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) d400_kl
  close(27)

  open(unit=27,file=trim(prname)//'d670_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) d670_kl
  close(27)

  open(unit=27,file=trim(prname)//'CMB_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) cmb_kl
  close(27)

  call create_name_database(prname,myrank,IREGION_OUTER_CORE,LOCAL_PATH)

  open(unit=27,file=trim(prname)//'ICB_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) icb_kl
  close(27)

  end subroutine save_kernels_boundary_kl

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_source_derivatives(nrec_local,NSOURCES,scale_displ,scale_t, &
                                nu_source,moment_der,sloc_der,stshift_der,shdur_der,number_receiver_global)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer nrec_local,NSOURCES
  double precision :: scale_displ,scale_t

  double precision :: nu_source(NDIM,NDIM,NSOURCES)
  real(kind=CUSTOM_REAL) :: moment_der(NDIM,NDIM,nrec_local),sloc_der(NDIM,nrec_local), &
                            stshift_der(nrec_local),shdur_der(nrec_local)

  integer, dimension(nrec_local) :: number_receiver_global

  ! local parameters
  real(kind=CUSTOM_REAL),parameter :: scale_mass = RHOAV * (R_EARTH**3)
  integer :: irec_local
  character(len=150) outputname

  !scale_mass = RHOAV * (R_EARTH**3)

  do irec_local = 1, nrec_local
    ! rotate and scale the location derivatives to correspond to dn,de,dz
    sloc_der(:,irec_local) = matmul(transpose(nu_source(:,:,irec_local)),sloc_der(:,irec_local)) &
                             * scale_displ * scale_t

    ! rotate scale the moment derivatives to correspond to M[n,e,z][n,e,z]
    moment_der(:,:,irec_local) = matmul(matmul(transpose(nu_source(:,:,irec_local)),moment_der(:,:,irec_local)),&
               nu_source(:,:,irec_local)) * scale_t ** 3 / scale_mass

   ! derivatives for time shift and hduration
    stshift_der(irec_local) = stshift_der(irec_local) * scale_displ**2
    shdur_der(irec_local) = shdur_der(irec_local) * scale_displ**2

    write(outputname,'(a,i5.5)') 'OUTPUT_FILES/src_frechet.',number_receiver_global(irec_local)
    open(unit=27,file=trim(outputname),status='unknown',action='write')
  !
  ! r -> z, theta -> -n, phi -> e, plus factor 2 for Mrt,Mrp,Mtp, and 1e-7 to dyne.cm
  !  Mrr =  Mzz
  !  Mtt =  Mnn
  !  Mpp =  Mee
  !  Mrt = -Mzn
  !  Mrp =  Mze
  !  Mtp = -Mne
  ! for consistency, location derivatives are in the order of [Xr,Xt,Xp]
  ! minus sign for sloc_der(3,irec_local) to get derivative for depth instead of radius

    write(27,'(g16.5)') moment_der(3,3,irec_local) * 1e-7
    write(27,'(g16.5)') moment_der(1,1,irec_local) * 1e-7
    write(27,'(g16.5)') moment_der(2,2,irec_local) * 1e-7
    write(27,'(g16.5)') -2*moment_der(1,3,irec_local) * 1e-7
    write(27,'(g16.5)') 2*moment_der(2,3,irec_local) * 1e-7
    write(27,'(g16.5)') -2*moment_der(1,2,irec_local) * 1e-7
    write(27,'(g16.5)') sloc_der(2,irec_local)
    write(27,'(g16.5)') sloc_der(1,irec_local)
    write(27,'(g16.5)') -sloc_der(3,irec_local)
    write(27,'(g16.5)') stshift_der(irec_local)
    write(27,'(g16.5)') shdur_der(irec_local)
    close(27)
  enddo

  end subroutine save_kernels_source_derivatives

!
!-------------------------------------------------------------------------------------------------
!

  subroutine save_kernels_hessian(myrank,scale_t,scale_displ, &
                  hess_kl_crust_mantle,LOCAL_PATH)

  implicit none

  include "constants.h"
  include "OUTPUT_FILES/values_from_mesher.h"

  integer myrank

  double precision :: scale_t,scale_displ

  real(kind=CUSTOM_REAL), dimension(NGLLX,NGLLY,NGLLZ,NSPEC_CRUST_MANTLE_ADJOINT) :: &
    hess_kl_crust_mantle

  character(len=150) LOCAL_PATH

  ! local parameters
  real(kind=CUSTOM_REAL) :: scale_kl
  character(len=150) prname

  ! scaling factors
  scale_kl = scale_t/scale_displ * 1.d9

  ! scales approximate hessian
  hess_kl_crust_mantle(:,:,:,:) = 2._CUSTOM_REAL * hess_kl_crust_mantle(:,:,:,:) * scale_kl

  ! stores into file
  call create_name_database(prname,myrank,IREGION_CRUST_MANTLE,LOCAL_PATH)

  open(unit=27,file=trim(prname)//'hess_kernel.bin',status='unknown',form='unformatted',action='write')
  write(27) hess_kl_crust_mantle
  close(27)

  end subroutine save_kernels_hessian

