@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Importes de mayor por documento'
// Neto del documento = suma de las líneas de mayor manuales (sin líneas
// automáticas de impuesto/retención). Signo: Debe (+) / Haber (-).
// El ajuste según ingresos/gastos se hace en ZI_MexInf2_Item.
define view entity ZI_MexInf2_GLAmt
  as select from bseg
{
  key bukrs     as Sociedad,
  key belnr     as NumeroDocumento,
  key gjahr     as Ejercicio,

      sum( case shkzg
             when 'H' then -1 * cast( wrbtr as abap.decfloat34 )
             else               cast( wrbtr as abap.decfloat34 )
           end )                                  as NetoMD,

      sum( case shkzg
             when 'H' then -1 * cast( dmbtr as abap.decfloat34 )
             else               cast( dmbtr as abap.decfloat34 )
           end )                                  as NetoML,

      min( hkont )                                as CuentaGasto,
      min( kostl )                                as Ceco
}
where
      koart =  'S'
  and xauto <> 'X'
  and ktosl =  ''
group by
  bukrs,
  belnr,
  gjahr
