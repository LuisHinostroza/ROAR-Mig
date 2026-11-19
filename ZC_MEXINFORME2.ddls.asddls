@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Informe de Retenciones ISR Exterior'
@UI.headerInfo: {
  typeName: 'Partida',
  typeNamePlural: 'Partidas',
  title: { type: #STANDARD, value: 'NumeroDocumento' }
}
define view entity ZC_MexInforme2
  as select from ZI_MexInf2_Item
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 70 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
  key Sociedad,

      @UI.lineItem:       [{ position: 20 }]
  key Ejercicio,

      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
  key NumeroDocumento,

      @UI.lineItem:       [{ position: 40 }]
  key Posicion,

      @UI.lineItem:       [{ position: 140 }]
      @EndUserText.label: 'Tipo retención'
  key TipoRetencion,

      // Radiobutton del reporte: D = Ingresos (por defecto), K = Gastos
      @UI.selectionField: [{ position: 10 }]
      @EndUserText.label: 'Ingresos (D) / Gastos (K)'
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false, defaultValue: 'D' }
      ClaseCuenta,

      @UI.lineItem:       [{ position: 50 }]
      FechaDocumento,

      @UI.lineItem:       [{ position: 60 }]
      @UI.selectionField: [{ position: 20 }]
      @Consumption.filter: { selectionType: #INTERVAL, mandatory: true }
      FechaContabilizacion,

      @UI.lineItem:       [{ position: 70 }]
      Periodo,

      @UI.lineItem:       [{ position: 80 }]
      @UI.selectionField: [{ position: 40 }]
      Referencia,

      // Solo visualización: se calcula en ABAP (texto YUUD). No filtrable ni ordenable.
      @UI.lineItem:       [{ position: 90 }]
      @EndUserText.label: 'Nuevo folio fiscal'
      @Consumption.filter.hidden: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_MEX_INF2_FOLIO'
      virtual NuevoFolioFiscal : abap.char( 255 ),

      @UI.lineItem:       [{ position: 100 }]
      @EndUserText.label: 'Importe MD'
      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( NetoMD * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )   as ImporteMD,

      @UI.lineItem:       [{ position: 105 }]
      @EndUserText.label: 'Moneda documento'
      MonedaMD,

      @UI.lineItem:       [{ position: 110 }]
      @EndUserText.label: 'Importe ML'
      @Semantics.amount.currencyCode: 'MonedaML'
      cast( NetoML * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )   as ImporteML,

      @EndUserText.label: 'Moneda local'
      MonedaML,

      @UI.lineItem:       [{ position: 120 }]
      IndicadorIVA,

      @UI.lineItem:       [{ position: 130 }]
      @EndUserText.label: 'Importe I.V.A.'
      @Semantics.amount.currencyCode: 'MonedaMD'
      cast( IvaMD * cast( FactorMayor as abap.decfloat34 ) as abap.curr( 23, 2 ) )    as ImporteIVA,

      @UI.lineItem:       [{ position: 145 }]
      @EndUserText.label: 'Código retención'
      CodigoRetencion,

      @UI.lineItem:       [{ position: 150 }]
      @EndUserText.label: 'Base retención'
      @Semantics.amount.currencyCode: 'MonedaMD'
      @Aggregation.default: #SUM
      cast( BaseRetencionAbs * cast( SignoDocumento as abap.decfloat34 )
            as abap.curr( 23, 2 ) )                                                   as BaseRetencion,

      @UI.lineItem:       [{ position: 160 }]
      @EndUserText.label: 'Importe retenido'
      @Semantics.amount.currencyCode: 'MonedaMD'
      @Aggregation.default: #SUM
      cast( ImporteRetenidoAbs * cast( SignoDocumento as abap.decfloat34 )
            as abap.curr( 23, 2 ) )                                                   as ImporteRetenido,

      @UI.lineItem:       [{ position: 170 }]
      DocCompensacion,

      @UI.lineItem:       [{ position: 180 }]
      FechaCompensacion,

      @UI.lineItem:       [{ position: 190 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_AccountingDocumentType', element: 'AccountingDocumentType' } }]
      ClaseDocumento,

      @UI.lineItem:       [{ position: 200 }]
      @UI.selectionField: [{ position: 50 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier_VH', element: 'Supplier' } }]
      Acreedor,

      @UI.lineItem:       [{ position: 210 }]
      @UI.selectionField: [{ position: 60 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer_VH', element: 'Customer' } }]
      Cliente,

      @UI.lineItem:       [{ position: 220 }]
      @EndUserText.label: 'R.F.C.'
      NIFTercero,

      @UI.lineItem:       [{ position: 230 }]
      @EndUserText.label: 'Nombre o razón social'
      NombreTercero,

      @UI.lineItem:       [{ position: 240 }]
      PaisTercero,

      @UI.lineItem:       [{ position: 250 }]
      CPTercero,

      @UI.lineItem:       [{ position: 260 }]
      @EndUserText.label: 'Cuenta gasto'
      CuentaGasto,

      @UI.lineItem:       [{ position: 270 }]
      @EndUserText.label: 'Cuenta I.V.A.'
      CuentaIVA,

      @UI.lineItem:       [{ position: 280 }]
      Texto,

      @UI.lineItem:       [{ position: 290 }]
      Ceco,

      @UI.lineItem:       [{ position: 300 }]
      UsuarioRegistro
}
