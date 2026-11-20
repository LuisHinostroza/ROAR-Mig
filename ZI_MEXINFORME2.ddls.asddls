@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Informe MX2 - Composite (cálculos y signos)'
define root view entity ZI_MexInforme2
  as select from ZI_MexInf2_Item
{
  key Sociedad,
  key Ejercicio,
  key NumeroDocumento,
  key Posicion,
  key TipoRetencion,

      ClaseCuenta,
      FechaDocumento,
      FechaContabilizacion,
      Periodo,
      Referencia,

      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( NetoMD * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )  as ImporteMD,
      MonedaMD,

      @Semantics.amount.currencyCode: 'MonedaML'
      cast( NetoML * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )  as ImporteML,
      MonedaML,

      IndicadorIVA,

      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( IvaMD * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )   as ImporteIVA,

      CodigoRetencion,

      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( BaseRetencionAbs * cast( SignoDocumento as abap.decfloat34 )
            as abap.curr( 23, 2 ) )                                                  as BaseRetencion,

      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( ImporteRetenidoAbs * cast( SignoDocumento as abap.decfloat34 )
            as abap.curr( 23, 2 ) )                                                  as ImporteRetenido,

      DocCompensacion,
      FechaCompensacion,
      ClaseDocumento,
      Acreedor,
      Cliente,
      NIFTercero,
      NombreTercero,
      PaisTercero,
      CPTercero,
      CuentaGasto,
      CuentaIVA,
      Texto,
      Ceco,
      UsuarioRegistro
}
