DELETE gm
FROM GroupMember gm
	INNER JOIN [Group] g ON g.Id = gm.GroupId
	WHERE g.GroupTypeId IN
        (37,38,39,40,41)
        
DELETE g 
--SELECT Count(id)
    FROM [Group] g
    WHERE g.GroupTypeId IN
        (37,38,39,40,41)
        
DBCC CHECKIDENT ([GroupMember], RESEED, 360899);