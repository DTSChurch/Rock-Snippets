-- =============================================
-- Author:      Steven Floyd <DTS>
-- Create Date: 01/30/2024
-- Description: Removes people from rock.
-- =============================================

CREATE TABLE #PersonIds (
    Id INT
);

insert into #PersonIds (Id) select Id FROM [Person] WHERE [Email] = 'sample@email.tst';

DELETE
FROM [AttributeValue]
WHERE [CreatedByPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [Assessment]
WHERE [CreatedByPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [Interaction]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonViewed]
WHERE [TargetPersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonSearchKey]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonDuplicate]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonDuplicate]
WHERE [DuplicatePersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [History]
WHERE [EntityId] IN (SELECT [Id] FROM #PersonIds);

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

DELETE
FROM [ConnectionRequestActivity]
WHERE [ConnectionRequestId] IN (
    SELECT [Id]
    FROM [ConnectionRequest]
    WHERE [PersonAliasId] IN (
        SELECT [Id]
        FROM [PersonAlias]
        WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
    )
);

DELETE
FROM [ConnectionRequest]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonAliasPersonalization]
WHERE [PersonAliasId] IN (
    SELECT [Id]
    FROM [PersonAlias]
    WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds)
);

DELETE
FROM [PersonAlias]
WHERE [PersonId] IN (SELECT [Id] FROM #PersonIds);

DELETE
FROM [Person]
WHERE [Id] IN (SELECT [Id] FROM #PersonIds);

DROP TABLE IF EXISTS  #PersonIds
