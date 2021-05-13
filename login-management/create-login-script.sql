use master;

SELECT
    CASE
      WHEN patindex('##%##', p.name) > 0 THEN NULL
      WHEN patindex('NT AUTHORITY\%', p.name) > 0 THEN NULL
      WHEN patindex('NT SERVICE\%', p.name) > 0 THEN NULL
      ELSE
        'CREATE LOGIN ' + QUOTENAME( p.name ) + ' ' +
        CASE p.type
          WHEN 'G' THEN 'FROM WINDOWS WITH '
          WHEN 'U' THEN 'FROM WINDOWS WITH '
          ELSE
            'WITH PASSWORD = ' +
            '0X' + CONVERT(VARCHAR(512),CAST( LOGINPROPERTY( p.name, 'PasswordHash' ) AS varbinary (256)),2) +
            ' HASHED, SID = ' +
            '0X' + CONVERT(VARCHAR(512),cast(p.sid as varbinary(256)),2 ) + ','
        END +
        ' DEFAULT_DATABASE = ' + QUOTENAME( p.default_database_name) +
        CASE p.type
          WHEN 'S' THEN
            CASE s.is_policy_checked
              WHEN 1 THEN ', CHECK_POLICY = ON'
              WHEN 0 THEN ', CHECK_POLICY = OFF'
              ELSE ''
            END +
            CASE s.is_expiration_checked
              WHEN 1 THEN ', CHECK_EXPIRATION = ON'
              WHEN 0 THEN ', CHECK_EXPIRATION = OFF'
              ELSE ''
            END
          ELSE ''
        END +
        CASE l.hasaccess
          WHEN 0 THEN '; DENY CONNECT SQL TO ' + QUOTENAME( p.name )
          ELSE '; GRANT CONNECT SQL TO ' + QUOTENAME( p.name )
        END +
        CASE l.denylogin
          WHEN 1 THEN '; REVOKE CONNECT SQL TO ' + QUOTENAME( p.name )
          ELSE ''
        END +
        CASE p.is_disabled
          WHEN 1 THEN '; ALTER LOGIN ' + QUOTENAME( p.name ) + ' DISABLE' 
          ELSE ''
        END +
        ';'
    END
    AS cmd
FROM
    sys.server_principals     p
    LEFT JOIN sys.syslogins   l ON ( l.name = p.name )
    LEFT JOIN sys.sql_logins  s ON ( s.name = p.name )
WHERE
    p.type IN ( 'S', 'G', 'U' )
    AND p.name <> 'sa'
    AND p.default_database_name IN ('master', 'Customer')
;
