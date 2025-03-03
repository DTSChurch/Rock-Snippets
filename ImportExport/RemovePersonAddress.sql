DELETE lh
	FROM GroupLocationHistorical lh 
	INNER JOIN GroupLocationHistorical glh on glh.LocationId = lh.Id AND glh.GroupLocationTypeValueId IN (19,20,1014)
	-- Note for Nov Import, I had to use: DELETE lh FROM GroupLocationHistorical lh

DELETE l
	FROM Location l
    INNER JOIN GroupLocation gl on gl.LocationId = l.Id AND gl.GroupLocationTypeValueId IN (19,20,1014)