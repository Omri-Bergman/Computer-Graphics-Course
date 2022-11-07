omri_bergman, omer_goldkorn
===============================================================================
Omri Bergman, ID 207543620, omri.bergman@mail.huji.ac.il
Omer Goldkorn, ID 315676148, omer.goldkorn@mail.huji.ac.il
===============================================================================

                          Exercise 2 - Meshes & Shading
                           -------------------------
  

Part 1 - question 6:

In the original CalculateNormals, we calculte the normal of each vertex based on the average of 
all the normals of the triangles that this vertex is taking part in (normalized sum of all the normals).

in the MakeFlatShadedֵ, we have expended the number of the vertexed in order to make sure the each triangle has 
three unique vrtexes, that are not shared with any other triangle. 
This way, the calculation of the normal of each vertex is based on only one triangle that it is part of, so each 
triangle defines the noramls of it's three unique vertexes, which are equal.

In the vertex shader stage, each point's value is interpolated according to the normals of the vertexes defines 
the face contains the point.
the MakeFlatShadedֵ causes that each point in the face will get the same value (because the interpulation is made 
between three equal values), so the color it will get in the frag shader will be the same -> so the whole face will
 be in the same color, and this causes the flat shading. 
 