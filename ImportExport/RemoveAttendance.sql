DECLARE @TempOccurrence TABLE (Id INT)

-- Temp set the occurrence as the Attendance needs to be removed first
INSERT INTO @TempOccurrence
SELECT DISTINCT a.OccurrenceId FROM Attendance a WHERE a.ForeignKey = 'Main'

--Remove Attendance
DELETE a
FROM Attendance a
WHERE a.ForeignKey = 'Main'

--Remove Occurrence
DELETE ao
FROM AttendanceOccurrence ao 
WHERE ao.Id IN (SELECT t.Id FROM @TempOccurrence t)

