@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - IVA por documento'
// IVA total del documento (BSET). Signo: Debe (+) / Haber (-).
define view entity ZI_MexInf2_Tax
  as select from bset
{
  key bukrs as Sociedad,
  key belnr as NumeroDocumento,
  key gjahr as Ejercicio,

      sum( case shkzg
             when 'H' then -1 * cast( fwste as abap.decfloat34 )
             else               cast( fwste as abap.decfloat34 )
           end )             as IvaMD,

      min( hkont )           as CuentaIVA
}
group by
  bukrs,
  belnr,
  gjahr
