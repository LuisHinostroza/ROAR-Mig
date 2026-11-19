@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Anulaciones (ZFI_CTES)'
define view entity ZI_MexInf2_CfgAnul
  as select distinct from zfi_ctes
{
  key clave3 as Koart,
  key valor1 as Blart,      // Clase del documento anulado
  key clave4 as BlartAnul   // Clase del documento de anulación
}
where
      clave1 =  'ZMFI_MEX_INFORME2'
  and clave2 =  'BLART'
  and clave4 <> ''
