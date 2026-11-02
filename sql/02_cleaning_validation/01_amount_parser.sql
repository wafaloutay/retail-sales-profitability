/* RetailTraining | 02 / 01
   Helper for price/cost/discount text. Reconstructed for this repository.
   - Recognizes e.g. '€19,99', '49,90', '1,299.00', '€720.00'.
   - Does NOT guess a single 3-digit separator (1.000 / 1,000).
   - Does not infer a currency or convert foreign exchange rates.
*/
USE RetailTraining;
GO

CREATE OR ALTER FUNCTION dbo.fn_TryRetailAmount (@Raw NVARCHAR(200))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @s NVARCHAR(200) = LTRIM(RTRIM(@Raw));
    IF @s IS NULL OR @s = N'' RETURN NULL;

    -- Remove only known display symbols and spaces. Do not remove minus signs.
    SET @s = REPLACE(@s, N'€', N'');
    SET @s = REPLACE(@s, N'$', N'');
    SET @s = REPLACE(@s, N'£', N'');
    SET @s = REPLACE(@s, NCHAR(160), N'');  -- non-breaking space
    SET @s = REPLACE(@s, N' ', N'');

    IF @s = N'' RETURN NULL;

    -- When comma and dot are both present, the rightmost separator is decimal.
    IF CHARINDEX(N',', @s) > 0 AND CHARINDEX(N'.', @s) > 0
    BEGIN
        IF CHARINDEX(N'.', REVERSE(@s)) < CHARINDEX(N',', REVERSE(@s))
            SET @s = REPLACE(@s, N',', N'');  -- 1,299.00 -> 1299.00
        ELSE
            SET @s = REPLACE(REPLACE(@s, N'.', N''), N',', N'.');
            -- 1.299,00 -> 1299.00
    END
    ELSE IF CHARINDEX(N',', @s) > 0
    BEGIN
        -- Potential thousands grouping: leave it for manual review.
        IF LEN(@s) - CHARINDEX(N',', @s) = 3 RETURN NULL;
        SET @s = REPLACE(@s, N',', N'.');
    END
    ELSE IF CHARINDEX(N'.', @s) > 0
    BEGIN
        IF LEN(@s) - CHARINDEX(N'.', @s) = 3 RETURN NULL;
    END;

    RETURN TRY_CONVERT(DECIMAL(18, 2), @s);
END;
GO

-- Non-destructive parser tests.
SELECT TestValue,
       dbo.fn_TryRetailAmount(TestValue) AS ParsedValue
FROM (VALUES
    (N'€19,99'), (N'49,90'), (N'1,299.00'),
    (N'€720.00'), (N'35,00'), (N'1.000$'), (N'not provided')
) AS Tests(TestValue);
