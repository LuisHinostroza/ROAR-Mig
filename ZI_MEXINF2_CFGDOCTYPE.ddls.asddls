@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Clases de documento (ZFI_CTES)'
define view entity ZI_MexInf2_CfgDocType
  as select distinct from zfi_ctes
{
  key clave3 as Koart,
  key valor1 as Blart
}
where
      clave1 = 'ZMFI_MEX_INFORME2'
  and clave2 = 'BLART'
