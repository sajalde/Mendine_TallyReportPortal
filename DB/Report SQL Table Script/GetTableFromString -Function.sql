USE [EasyReports3.6]
GO
/****** Object:  UserDefinedFunction [dbo].[GetTableFromString]    Script Date: 11/22/2020 6:45:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
ALTER FUNCTION [dbo].[GetTableFromString] 
(
	@list varchar(MAX)
)

RETURNS @tbl TABLE (name varchar(max) NOT NULL) 
AS
BEGIN
   DECLARE @pos        int,
           @nextpos    int,
           @valuelen   int
   SELECT @pos = 0, @nextpos = 1
   
   WHILE @nextpos > 0
   BEGIN
      SELECT @nextpos = charindex(',', @list, @pos + 1)
      SELECT @valuelen = CASE WHEN @nextpos > 0
                              THEN @nextpos
                              ELSE len(@list) + 1
                         END - @pos - 1
      INSERT @tbl (name)
         VALUES (convert(varchar(max), substring(@list, @pos + 1, @valuelen)))
      SELECT @pos = @nextpos
   END
  RETURN 

END
