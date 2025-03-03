-- =============================================
-- Author:      Steven Floyd <DTS>
-- Create Date: 01/30/2024
-- Description: Removes people from rock.
-- =============================================

CREATE TABLE #PersonIds (
    Id INT
);

insert into #PersonIds (Id) select Id FROM [Person] WHERE [ForeignKey] = 'MainNeedRemoved';

SELECT * FROM #PersonIds
--Attribute Value 188K
DELETE
FROM [AttributeValue]
WHERE [CreatedByPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Assessments 0
DELETE
FROM [Assessment]
WHERE [CreatedByPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Interactions 0
DELETE
FROM [Interaction]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Person Viewed 0
DELETE
FROM [PersonViewed]
WHERE [TargetPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Person Viewed Viewer
DELETE
FROM [PersonViewed]
WHERE ViewerPersonAliasId IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Person Search Key 0
DELETE
FROM [PersonSearchKey]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Person Duplicate (Main Person) 0
DELETE
FROM [PersonDuplicate]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--Person Duplicate (Other Person) 1
DELETE
FROM [PersonDuplicate]
WHERE [DuplicatePersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

--History 70
DELETE
FROM [History]
WHERE [EntityId] IN (SELECT [Id] FROM #PersonIds);

--History Created BY
DELETE
FROM [History]
WHERE [CreatedByPersonAliasId] IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Empty Person.ModifiedByPersonAliasId of people who are needing deleted. 188K
UPDATE p
Set p.ModifiedByPersonAliasId = NULL
FROM Person p WHERE p.Id IN (
	SELECT [Id] FROM #PersonIds);

-- Empty Group.ModifiedByPersonAliasId of people who are needing deleted. 188K
UPDATE g
Set g.ModifiedByPersonAliasId = NULL
FROM [Group] g WHERE g.ModifiedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Empty Group.CreatedByPersonAliasId of people who are needing deleted. 188K
UPDATE g
Set g.CreatedByPersonAliasId = NULL
FROM [Group] g WHERE g.CreatedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

--Group Historical 0
DELETE gh
FROM GroupHistorical gh
WHERE gh.ModifiedByPersonAliasId IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds));

--Group Member Historical 0
DELETE gmh
FROM GroupMemberHistorical gmh
WHERE gmh.GroupMemberId IN (SELECT gm.[Id] FROM [GroupMember] gm INNER JOIN #PersonIds p on p.Id = gm.PersonId);

-- Remove GroupMembers Created By
UPDATE gm
SET gm.CreatedByPersonAliasId = NULL, gm.ModifiedByPersonAliasId = NULL
FROM GroupMember gm
WHERE gm.CreatedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Empty InteractionComponent.CreatedByPersonAliasId of people who are needing deleted. 188K
UPDATE ic
Set ic.CreatedByPersonAliasId = NULL
FROM InteractionComponent ic WHERE ic.CreatedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Empty InteractionComponent.ModifiedByPersonAliasId of people who are needing deleted. 188K
UPDATE ic
Set ic.ModifiedByPersonAliasId = NULL
FROM InteractionComponent ic WHERE ic.ModifiedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Remove Notes
DELETE n
FROM Note n
WHERE n.CreatedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Communication Recipient
DELETE cr
FROM CommunicationRecipient cr
WHERE cr.PersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Notification Recipient
DELETE nr
FROM NotificationRecipient nr
WHERE nr.PersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));



--Attribute
UPDATE a
SET a.CreatedByPersonAliasId = NULL, a.ModifiedByPersonAliasId = NULL
FROM Attribute a
WHERE a.CreatedByPersonAliasId IN (SELECT pa.[Id] FROM PersonAlias pa WHERE pa.PersonId IN (SELECT Id FROM #PersonIds));

-- Person Alias 188K
DELETE
FROM [PersonAlias]
WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds);


--Last but not least.... The Person 188065
DELETE
FROM [Person]
WHERE [Id] IN (SELECT [Id] FROM #PersonIds);

DROP TABLE IF EXISTS  #PersonIds
GO
