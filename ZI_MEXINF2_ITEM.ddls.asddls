@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Línea de tercero x retención'
// Granularidad: una fila por línea de acreedor/deudor y tipo de retención.
// Signos (ref. incidencia 1000040300):
//   Facturas en positivo, abonos/notas de crédito y anulaciones en negativo.
//   Gastos (K): tercero en Haber = factura.  Ingresos (D): tercero en Debe = factura.
define view entity ZI_MexInf2_Item
  as select from    bseg                  as p

    inner join      bkpf                  as h   on  h.bukrs = p.bukrs
                                                 and h.belnr = p.belnr
                                                 and h.gjahr = p.gjahr

    inner join      t001                  as cc  on  cc.bukrs = p.bukrs

  // Indicador de impuestos configurado para la clase de cuenta
    inner join      ZI_MexInf2_CfgTax     as ct  on  ct.Koart = p.koart
                                                 and ct.Mwskz = p.mwskz

  // Clase de documento configurada
    left outer join ZI_MexInf2_CfgDocType as cd  on  cd.Koart = p.koart
                                                 and cd.Blart = h.blart

  // Anulación: el documento anulado debe tener una clase configurada
  // y la pareja clase/anulación debe existir en ZFI_CTES
    left outer join bkpf                  as rev on  rev.bukrs = h.bukrs
                                                 and rev.belnr = h.stblg
                                                 and rev.gjahr = h.stjah
    left outer join ZI_MexInf2_CfgAnul    as ca  on  ca.Koart     = p.koart
                                                 and ca.BlartAnul = h.blart
                                                 and ca.Blart     = rev.blart

  // Retenciones de la línea del tercero (por llave, sin productos cruzados)
    left outer join with_item             as w   on  w.bukrs = p.bukrs
                                                 and w.belnr = p.belnr
                                                 and w.gjahr = p.gjahr
                                                 and w.buzei = p.buzei

    left outer join ZI_MexInf2_GLAmt      as gl  on  gl.Sociedad        = p.bukrs
                                                 and gl.NumeroDocumento = p.belnr
                                                 and gl.Ejercicio       = p.gjahr

    left outer join ZI_MexInf2_Tax        as tx  on  tx.Sociedad        = p.bukrs
                                                 and tx.NumeroDocumento = p.belnr
                                                 and tx.Ejercicio       = p.gjahr

  // Terceros: primero BSEC (ocasionales), si no LFA1 / KNA1
    left outer join bsec                  as sc  on  sc.bukrs = p.bukrs
                                                 and sc.belnr = p.belnr
                                                 and sc.gjahr = p.gjahr
                                                 and sc.buzei = p.buzei
    left outer join lfa1                  as lf  on  lf.lifnr = p.lifnr
    left outer join kna1                  as kn  on  kn.kunnr = p.kunnr
{
  p.bukrs                                              as Sociedad,
  p.gjahr                                              as Ejercicio,
  p.belnr                                              as NumeroDocumento,
  p.buzei                                              as Posicion,
  coalesce( w.witht, cast( '' as witht ) )             as TipoRetencion,

  p.koart                                              as ClaseCuenta,
  h.bldat                                              as FechaDocumento,
  h.budat                                              as FechaContabilizacion,
  h.monat                                              as Periodo,
  h.xblnr                                              as Referencia,
  h.blart                                              as ClaseDocumento,
  h.usnam                                              as UsuarioRegistro,
  h.waers                                              as MonedaMD,
  cc.waers                                             as MonedaML,

  // Signo del documento: +1 factura / -1 abono o anulación
  case
    when ( p.koart = 'K' and p.shkzg = 'H' )
      or ( p.koart = 'D' and p.shkzg = 'S' ) then  1
    else                                          -1
  end                                                  as SignoDocumento,

  // Factor para las líneas de mayor e IVA (Debe + en gastos, invertido en ingresos)
  case p.koart when 'D' then -1 else 1 end             as FactorMayor,

  gl.NetoMD                                            as NetoMD,
  gl.NetoML                                            as NetoML,
  gl.CuentaGasto                                       as CuentaGasto,
  gl.Ceco                                              as Ceco,

  p.mwskz                                              as IndicadorIVA,
  tx.IvaMD                                             as IvaMD,
  tx.CuentaIVA                                         as CuentaIVA,

  w.wt_withcd                                          as CodigoRetencion,
  abs( cast( w.wt_qsshb as abap.decfloat34 ) )         as BaseRetencionAbs,
  abs( cast( w.wt_qbshb as abap.decfloat34 ) )         as ImporteRetenidoAbs,

  p.augbl                                              as DocCompensacion,
  p.augdt                                              as FechaCompensacion,
  p.lifnr                                              as Acreedor,
  p.kunnr                                              as Cliente,
  p.sgtxt                                              as Texto,

  coalesce( sc.stcd1, coalesce( lf.stcd1, kn.stcd1 ) ) as NIFTercero,
  coalesce( sc.name1, coalesce( lf.name1, kn.name1 ) ) as NombreTercero,
  coalesce( sc.land1, coalesce( lf.land1, kn.land1 ) ) as PaisTercero,
  coalesce( sc.pstlz, coalesce( lf.pstlz, kn.pstlz ) ) as CPTercero
}
where
  (    p.koart = 'K'
    or p.koart = 'D' )
  and (    cd.Blart is not null
        or ca.Blart is not null )
