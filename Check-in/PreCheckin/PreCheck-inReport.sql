-- =============================================
-- Author:      DTS - Michael Roth
-- Create date: 2020-08-07
-- Description: Will show who has pre checked in using the DTS Contactless Check-in
-- =============================================

{% if PageParameter.CampusId %}
SET @CampusId = {{PageParameter.CampusId}}
{%endif%}

SELECT p.NickName
	,p.LastName
	,c.ShortCode AS Campus
	,g.Name [Group]
	,l.Name Location
	,s.Name Schedule
	,ac.Code
	,a.CreatedDateTime AS PreCheckedInDateTime
	,CASE WHEN a.DidAttend = 1
		THEN a.ModifiedDateTime
		ELSE NULL 
		END AS CheckedInDateTime
	FROM Attendance a
		INNER JOIN AttendanceOccurrence ao on a.OccurrenceId = ao.Id
		INNER JOIN PersonAlias pa ON pa.Id = a.PersonAliasId
		INNER JOIN Person p ON p.Id = pa.PersonId
		INNER JOIN [Group] g ON g.Id = ao.GroupId
		INNER JOIN Location l ON l.Id = ao.LocationId
		INNER JOIN Schedule s ON s.Id = ao.ScheduleId
		INNER JOIN AttendanceCode ac ON ac.Id = a.AttendanceCodeId
		INNER JOIN Campus c ON c.Id = a.CampusId
	WHERE a.ForeignKey <> ''
		AND Convert(Date,ao.OccurrenceDate)>= Convert(Date,GetDate()-6)
		{% if PageParameter.CampusId %}AND a.CampusId = {{PageParameter.CampusId}}{%endif%}
		ORDER BY s.Name,l.Name,a.CreatedDateTime