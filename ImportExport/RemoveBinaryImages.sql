-- remove Images
DELETE bfd
FROM BinaryFileData bfd
	INNER JOIN BinaryFile bf ON bfd.Id = bf.Id
WHERE bf.BinaryFileTypeId = 2 --AND bf.Id = 140

DELETE bf
FROM BinaryFile bf
WHERE bf.BinaryFileTypeId = 2 --AND bf.Id = 140