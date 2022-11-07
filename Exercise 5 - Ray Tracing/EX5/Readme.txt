Omri Bergman 207543620 omri_bergman
Omer Goldkorn 315676148 omer_goldkorn



Part 4/8 - Refractions:

We wanted to match the example from the practice where we used a 3X3 board. (meaning each square is 1/3 X 1/3)
So we multiplied by 2 and made Modulo 2 because we wanted each square to be 1/2 X 1/2 in size.

(floor(bestHit.position.x*2) + floor(bestHit.position.z*2))%2)

Therefore, if it comes out 0 then we are in the square in the first material, and if it comes out 1 then in the second material.




Part 5/3 - Cylinder:

we have calculated the intersection point by first solving the quadratic equation of:

f(p) = f(x,y,z) = (x-c_x)^2 + (z-c_z)^3 - r^2 = 0

where:
	x = ray.origin.x + t*ray.direction.x
	z = ray.origin.z + t*ray.direction.z	
	
in order to find out if there is a horizontal circle that is parallel to the cylinder's base which
is intersect with the ray.

and then checking that ray.origin.y + t*ray.direction.y is in [cylinder.y - h/w, cylinder.y + h/w] - 
meaning it is in the vertical scope of the cylinder.

