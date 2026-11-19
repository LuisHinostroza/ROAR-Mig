@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Indicadores de impuesto (ZFI_CTES)'
define view entity ZI_MexInf2_CfgTax
  as select distinct from zfi_ctes
{
  key clave3 as Koart,
  key valor1 as Mwskz
}
where
      clave1 = 'ZMFI_MEX_INFORME2'
  and clave2 = 'MWSKZ'
