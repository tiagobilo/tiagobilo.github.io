function r = rhs_isw_umomentum(u,v,eta,dx,dy,a,f,g,H,mask)
	%
	% Compute time-tendency of the zonal velocity
	%
	% usage is
	% r = rhs_isw_umomentum(u,eta,dx,dy,a,f,g,H)
	% where u,v: are the velocity components
	%
	%       eta: is the sea-surface height field at the current time step
	% 
	%       dx,dy: is the zonal grid spacing
	%
	%		a: non-linear terms parameter.
	%
	%		f: planetary vorticity
	%
	%		g: acceleration due to gravity
	%
	%		H: local depth
	%
	%		mask: topographic mask
	%
	% Author: Tiago Bilo
	% CFD - Fall 2016
	% Class Project


	% Verifying size of H (if H = cte, it will be expanded to all grid cell centers)
	if length(H) == 1
		H = ones(size(eta))*H;
	end

	% Total water column height
	h = H+eta;


	%%%%%%%%%%
	%% Compute meridional mass flux V
	%%%%%%%%%%
	hv = xop2_2d(v,h,0.0,[0.5 0.5]); 									% average depth at v grid points		
	V = v.*hv;															% Meridional mass flux V far from the boundaries (at boundaries = 0.0)



	%%%%%%%%%%
	%% Compute potential vorticity q
	%%%%%%%%%%
	ha = zeros(size(eta)+1);											% Average water column height at vorticity points (i. e., far from boundaries) 
	ha(2:end,:) = yop2_2d(u,hv(2:end,:),0.0,[0.5 0.5]); 


	% Enforcing that potential vorticity is not defined at the boundaries
	ha([1 end],:) = nan;
	ha(:,[1 end]) = nan;

	dvdx = zeros(size(eta)+1);
	dudy = zeros(size(eta)+1);

	dvdx(2:end,:) = yop2_2d(u,v(2:end,:),0.0,[1/dx -1/dx]);
	dudy(:,2:end) = xop2_2d(v,u(:,2:end),0.0,[1/dy -1/dy]);

	q = (dvdx-dudy+f)./ha;

	% Removing NaNs
	q([1 end],:) = 0.0;
	q(:,[1 end]) = 0.0;



	%%%%%%%%%%
	%% Compute total head PHI and its x-derivative
	%%%%%%%%%%
	u2 = u.*u;
	v2 = v.*v; 

	u2 = yop2_2d(eta,u2,0.0,[0.5 0.5]);
	v2 = xop2_2d(eta,v2,0.0,[0.5 0.5]);

	PHI = g*eta + a*(u2+v2)/2.0;
	dPHI = yop2_2d(u,PHI,0.0,[1.0/dx -1.0/dx]);



	%%%%%%%%%%
	%% Compute Coriolis term
	%%%%%%%%%%
	Vx = yop2_2d(q,V,0.0,[0.5 0.5]);
	C = xop2_2d(u,q.*Vx,0.0,[0.5 0.5]);	


	% time-tendency of the zonal velocity 
	r = C-dPHI;

	% Enforcing boundary conditions
	% Closed boundaries: No normal flow at the boundaries (i. e., no u tendencies)
	r(:,[1 end]) = 0.0;
	r = r.*mask;
