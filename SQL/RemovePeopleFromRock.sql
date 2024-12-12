-- =============================================
-- Author:      Steven Floyd <DTS>
-- Create Date: 01/30/2024
-- Description: Removes people from rock.
-- =============================================

CREATE TABLE #PersonIds (
    Id INT
);

insert into #PersonIds (Id) select Id FROM [Person] WHERE [FirstName] LIKE '%BITCOIN%';

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

-- Empty Person.ModifiedByPersonAliasId of people who are needing deleted. 188K
UPDATE p
Set p.ModifiedByPersonAliasId = NULL
FROM Person p WHERE p.Id IN (
	SELECT [Id] FROM #PersonIds);

DELETE 
FROM [CommunicationRecipient]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

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
