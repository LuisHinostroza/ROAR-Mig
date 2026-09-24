CLASS zcl_mex_informe_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.
    CONSTANTS:
      c_msgid       TYPE symsgid VALUE 'ZMFI_MEX_INFORME_MSG',
      c_folio_field TYPE string  VALUE `NUEVOFOLIOFISCAL`.

    TYPES:
      ty_row  TYPE zce_mexinforme,
      tt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,

      tt_r_bukrs TYPE RANGE OF bukrs,
      tt_r_gjahr TYPE RANGE OF gjahr,
      tt_r_budat TYPE RANGE OF budat,
      tt_r_belnr TYPE RANGE OF belnr_d,
      tt_r_xblnr TYPE RANGE OF xblnr1,
      tt_r_lifnr TYPE RANGE OF lifnr,
      tt_r_kunnr TYPE RANGE OF kunnr,

      " Equivalente a la pantalla de selección del reporte
      BEGIN OF ty_sel,
        bukrs TYPE tt_r_bukrs,
        gjahr TYPE tt_r_gjahr,
        budat TYPE tt_r_budat,
        belnr TYPE tt_r_belnr,
        xblnr TYPE tt_r_xblnr,
        lifnr TYPE tt_r_lifnr,
        kunnr TYPE tt_r_kunnr,
      END OF ty_sel,

      BEGIN OF ty_t001,
        bukrs TYPE bukrs,
        waers TYPE waers,
      END OF ty_t001,
      tt_t001 TYPE SORTED TABLE OF ty_t001 WITH UNIQUE KEY bukrs,

      BEGIN OF ty_doc_key,
        bukrs TYPE bukrs,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
      END OF ty_doc_key,
      tt_doc_keys TYPE STANDARD TABLE OF ty_doc_key WITH EMPTY KEY,

      BEGIN OF ty_bkpf,
        bukrs TYPE bukrs,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
        blart TYPE blart,
        bldat TYPE bldat,
        budat TYPE budat,
        monat TYPE monat,
        xblnr TYPE xblnr1,
        waers TYPE waers,
        usnam TYPE usnam,
      END OF ty_bkpf,
      tt_bkpf TYPE SORTED TABLE OF ty_bkpf WITH UNIQUE KEY bukrs belnr gjahr,

      BEGIN OF ty_bseg,
        bukrs TYPE bukrs,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
        buzei TYPE buzei,
        augbl TYPE augbl,
        augdt TYPE augdt,
        lifnr TYPE lifnr,
        kunnr TYPE kunnr,
        wrbtr TYPE wrbtr,
        dmbtr TYPE dmbtr,
        mwskz TYPE mwskz,
        sgtxt TYPE sgtxt,
      END OF ty_bseg,
      tt_bseg TYPE SORTED TABLE OF ty_bseg WITH UNIQUE KEY bukrs belnr gjahr buzei,

      BEGIN OF ty_gasto,
        bukrs TYPE bukrs,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
        buzei TYPE buzei,
        hkont TYPE hkont,
        kostl TYPE kostl,
      END OF ty_gasto,
      tt_gasto TYPE SORTED TABLE OF ty_gasto WITH UNIQUE KEY bukrs belnr gjahr buzei,

      BEGIN OF ty_bset,
        bukrs TYPE bukrs,
        belnr TYPE belnr_d,
        gjahr TYPE gjahr,
        buzei TYPE buzei,
        mwskz TYPE mwskz,
        fwste TYPE fwste,
        hkont TYPE hkont,
      END OF ty_bset,
      tt_bset TYPE SORTED TABLE OF ty_bset WITH UNIQUE KEY bukrs belnr gjahr buzei,

      BEGIN OF ty_with,
        bukrs    TYPE bukrs,
        belnr    TYPE belnr_d,
        gjahr    TYPE gjahr,
        buzei    TYPE buzei,
        witht    TYPE witht,
        wt_qbshb TYPE wt_wt1,
      END OF ty_with,
      tt_with TYPE SORTED TABLE OF ty_with WITH UNIQUE KEY bukrs belnr gjahr buzei witht,

      BEGIN OF ty_lfa1,
        lifnr TYPE lifnr,
        name1 TYPE name1_gp,
        stcd1 TYPE stcd1,
        land1 TYPE land1_gp,
        pstlz TYPE pstlz,
      END OF ty_lfa1,
      tt_lfa1 TYPE HASHED TABLE OF ty_lfa1 WITH UNIQUE KEY lifnr,

      BEGIN OF ty_kna1,
        kunnr TYPE kunnr,
        name1 TYPE name1_gp,
        stcd1 TYPE stcd1,
        land1 TYPE land1_gp,
        pstlz TYPE pstlz,
      END OF ty_kna1,
      tt_kna1 TYPE HASHED TABLE OF ty_kna1 WITH UNIQUE KEY kunnr.

    METHODS get_range
      IMPORTING it_filters      TYPE if_rap_query_filter=>tt_name_range_pairs
                iv_name         TYPE string
      RETURNING VALUE(rt_range) TYPE if_rap_query_filter=>tt_range_option.

    METHODS build_rows
      IMPORTING is_sel         TYPE ty_sel
      RETURNING VALUE(rt_rows) TYPE tt_rows
      RAISING   zcx_mex_informe.

    METHODS fill_folio
      CHANGING ct_rows TYPE tt_rows.

    METHODS apply_filters
      IMPORTING it_filters TYPE if_rap_query_filter=>tt_name_range_pairs
      CHANGING  ct_rows    TYPE tt_rows.

ENDCLASS.



CLASS zcl_mex_informe_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA lt_page TYPE tt_rows.

    " Filtro, orden y paginación se leen siempre (el framework verifica que se consuman)
    DATA(lt_filters)   = io_request->get_filter( )->get_as_ranges( ).
    DATA(lt_sort)      = io_request->get_sort_elements( ).
    DATA(lo_paging)    = io_request->get_paging( ).
    DATA(lt_requested) = io_request->get_requested_elements( ).

    " Pantalla de selección del reporte
    DATA(ls_sel) = VALUE ty_sel(
      bukrs = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `SOCIEDAD` ) )
      gjahr = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `EJERCICIO` ) )
      budat = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `FECHACONTABILIZACION` ) )
      belnr = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `NUMERODOCUMENTO` ) )
      xblnr = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `REFERENCIA` ) )
      lifnr = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `ACREEDOR` ) )
      kunnr = CORRESPONDING #( get_range( it_filters = lt_filters iv_name = `CLIENTE` ) ) ).

    " s_budat era OBLIGATORY: también se valida en servidor.
    " Excepción: lectura por clave (clic en una fila / refresco de un registro),
    " donde Fiori manda Sociedad + Ejercicio + Documento + Posición sin fecha.
    IF ls_sel-budat IS INITIAL
       AND ( ls_sel-belnr IS INITIAL OR ls_sel-gjahr IS INITIAL ).
      RAISE EXCEPTION TYPE zcx_mex_informe MESSAGE ID c_msgid TYPE 'E' NUMBER '004'.
    ENDIF.

    DATA(lt_rows) = build_rows( ls_sel ).

    " El folio se lee para todo el resultado solo si se filtra u ordena por él;
    " si no, solo para las filas de la página que se devuelve
    DATA(lv_folio_all) = xsdbool( line_exists( lt_filters[ name = c_folio_field ] )
                               OR line_exists( lt_sort[ element_name = c_folio_field ] ) ).

    IF lv_folio_all = abap_true.
      fill_folio( CHANGING ct_rows = lt_rows ).
    ENDIF.

    apply_filters( EXPORTING it_filters = lt_filters
                   CHANGING  ct_rows    = lt_rows ).

    " Orden: el del usuario o, por defecto, el del reporte
    DATA(lt_order) = VALUE abap_sortorder_tab(
      FOR ls_sort IN lt_sort ( name = ls_sort-element_name descending = ls_sort-descending ) ).
    IF lt_order IS INITIAL.
      lt_order = VALUE #( ( name = 'SOCIEDAD' )
                          ( name = 'EJERCICIO' )
                          ( name = 'NUMERODOCUMENTO' )
                          ( name = 'POSICION' ) ).
    ENDIF.
    SORT lt_rows BY (lt_order).

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( lt_rows ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      DATA(lv_from)      = CONV i( lo_paging->get_offset( ) ) + 1.
      DATA(lv_page_size) = lo_paging->get_page_size( ).
      DATA(lv_to)        = COND i( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited
                                   THEN lines( lt_rows )
                                   ELSE lv_from + lv_page_size - 1 ).

      LOOP AT lt_rows INTO DATA(ls_row) FROM lv_from TO lv_to.
        APPEND ls_row TO lt_page.
      ENDLOOP.

      IF lv_folio_all = abap_false
         AND ( lt_requested IS INITIAL
            OR line_exists( lt_requested[ table_line = c_folio_field ] ) ).
        fill_folio( CHANGING ct_rows = lt_page ).
      ENDIF.

      io_response->set_data( lt_page ).
    ENDIF.
  ENDMETHOD.


  METHOD get_range.
    READ TABLE it_filters INTO DATA(ls_filter) WITH KEY name = iv_name.
    IF sy-subrc = 0.
      rt_range = ls_filter-range.
    ENDIF.
  ENDMETHOD.


  METHOD build_rows.
    DATA: lt_t001  TYPE tt_t001,
          lt_keys  TYPE tt_doc_keys,
          lt_bkpf  TYPE tt_bkpf,
          lt_bseg  TYPE tt_bseg,
          lt_gasto TYPE tt_gasto,
          lt_bset  TYPE tt_bset,
          lt_with  TYPE tt_with,
          lt_lfa1  TYPE tt_lfa1,
          lt_kna1  TYPE tt_kna1,
          ls_row   TYPE ty_row,
          lv_tabix TYPE sy-tabix.

*----------------------------------------------------------------------*
* 1. Sociedades de México (get_t001)
*----------------------------------------------------------------------*
    SELECT bukrs, waers
      FROM t001
      WHERE bukrs IN @is_sel-bukrs
        AND land1 = 'MX'
      INTO CORRESPONDING FIELDS OF TABLE @lt_t001.

    IF lt_t001 IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mex_informe MESSAGE ID c_msgid TYPE 'E' NUMBER '001'.
    ENDIF.

    " Autorización por sociedad (nuevo; el reporte no la validaba)
    LOOP AT lt_t001 INTO DATA(ls_t001).
      lv_tabix = sy-tabix.
      AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
        ID 'BUKRS' FIELD ls_t001-bukrs
        ID 'ACTVT' FIELD '03'.
      IF sy-subrc <> 0.
        DELETE lt_t001 INDEX lv_tabix.
      ENDIF.
    ENDLOOP.

    IF lt_t001 IS INITIAL.
      RAISE EXCEPTION TYPE zcx_mex_informe MESSAGE ID c_msgid TYPE 'E' NUMBER '003'.
    ENDIF.

*----------------------------------------------------------------------*
* 2. Cabeceras (get_bkpf) - misma lógica que el reporte
*----------------------------------------------------------------------*
    IF is_sel-lifnr IS NOT INITIAL OR is_sel-kunnr IS NOT INITIAL.

      " Optimización por tercero: índices de partidas abiertas/compensadas
      IF is_sel-lifnr IS NOT INITIAL.
        SELECT bukrs, belnr, gjahr
          FROM bsik
          FOR ALL ENTRIES IN @lt_t001
          WHERE bukrs = @lt_t001-bukrs
            AND lifnr IN @is_sel-lifnr
            AND gjahr IN @is_sel-gjahr
            AND budat IN @is_sel-budat
          APPENDING CORRESPONDING FIELDS OF TABLE @lt_keys.

        SELECT bukrs, belnr, gjahr
          FROM bsak
          FOR ALL ENTRIES IN @lt_t001
          WHERE bukrs = @lt_t001-bukrs
            AND lifnr IN @is_sel-lifnr
            AND gjahr IN @is_sel-gjahr
            AND budat IN @is_sel-budat
          APPENDING CORRESPONDING FIELDS OF TABLE @lt_keys.
      ENDIF.

      IF is_sel-kunnr IS NOT INITIAL.
        SELECT bukrs, belnr, gjahr
          FROM bsid
          FOR ALL ENTRIES IN @lt_t001
          WHERE bukrs = @lt_t001-bukrs
            AND kunnr IN @is_sel-kunnr
            AND gjahr IN @is_sel-gjahr
            AND budat IN @is_sel-budat
          APPENDING CORRESPONDING FIELDS OF TABLE @lt_keys.

        SELECT bukrs, belnr, gjahr
          FROM bsad
          FOR ALL ENTRIES IN @lt_t001
          WHERE bukrs = @lt_t001-bukrs
            AND kunnr IN @is_sel-kunnr
            AND gjahr IN @is_sel-gjahr
            AND budat IN @is_sel-budat
          APPENDING CORRESPONDING FIELDS OF TABLE @lt_keys.
      ENDIF.

      IF lt_keys IS NOT INITIAL.
        SELECT bukrs, belnr, gjahr, blart, bldat, budat, monat, xblnr, waers, usnam
          FROM bkpf
          FOR ALL ENTRIES IN @lt_keys
          WHERE bukrs = @lt_keys-bukrs
            AND belnr = @lt_keys-belnr
            AND gjahr = @lt_keys-gjahr
            AND gjahr IN @is_sel-gjahr
            AND budat IN @is_sel-budat
            AND belnr IN @is_sel-belnr
            AND xblnr IN @is_sel-xblnr
            AND bstat = @space
          INTO CORRESPONDING FIELDS OF TABLE @lt_bkpf.
      ENDIF.

    ELSE.

      SELECT bukrs, belnr, gjahr, blart, bldat, budat, monat, xblnr, waers, usnam
        FROM bkpf
        FOR ALL ENTRIES IN @lt_t001
        WHERE bukrs = @lt_t001-bukrs
          AND gjahr IN @is_sel-gjahr
          AND budat IN @is_sel-budat
          AND belnr IN @is_sel-belnr
          AND xblnr IN @is_sel-xblnr
          AND bstat = @space
        INTO CORRESPONDING FIELDS OF TABLE @lt_bkpf.

    ENDIF.

    " Sin datos: en Fiori simplemente la tabla vacía
    IF lt_bkpf IS INITIAL.
      RETURN.
    ENDIF.

*----------------------------------------------------------------------*
* 3. Posiciones (get_bseg)
*    Se replica el WHERE original: con un rango vacío, "IN" es verdadero,
*    así que salen todas las posiciones no automáticas del documento.
*----------------------------------------------------------------------*
    SELECT bukrs, belnr, gjahr, buzei, augbl, augdt, lifnr, kunnr,
           wrbtr, dmbtr, mwskz, sgtxt
      FROM bseg
      FOR ALL ENTRIES IN @lt_bkpf
      WHERE bukrs = @lt_bkpf-bukrs
        AND belnr = @lt_bkpf-belnr
        AND gjahr = @lt_bkpf-gjahr
        AND ( lifnr IN @is_sel-lifnr OR kunnr IN @is_sel-kunnr )
        AND buzid = @space
      INTO CORRESPONDING FIELDS OF TABLE @lt_bseg.

    IF lt_bseg IS INITIAL.
      RETURN.
    ENDIF.

    " Líneas de gasto (cuentas 5*)
    SELECT bukrs, belnr, gjahr, buzei, hkont, kostl
      FROM bseg
      FOR ALL ENTRIES IN @lt_bkpf
      WHERE bukrs = @lt_bkpf-bukrs
        AND belnr = @lt_bkpf-belnr
        AND gjahr = @lt_bkpf-gjahr
        AND hkont BETWEEN '5000000000' AND '5999999999'
        AND buzid = @space
        AND koart = 'S'
      INTO CORRESPONDING FIELDS OF TABLE @lt_gasto.

*----------------------------------------------------------------------*
* 4. Datos auxiliares
*----------------------------------------------------------------------*
    " A) Impuestos
    SELECT bukrs, belnr, gjahr, buzei, mwskz, fwste, hkont
      FROM bset
      FOR ALL ENTRIES IN @lt_bkpf
      WHERE bukrs = @lt_bkpf-bukrs
        AND belnr = @lt_bkpf-belnr
        AND gjahr = @lt_bkpf-gjahr
      INTO CORRESPONDING FIELDS OF TABLE @lt_bset.

    " B) Retenciones
    SELECT bukrs, belnr, gjahr, buzei, witht, wt_qbshb
      FROM with_item
      FOR ALL ENTRIES IN @lt_bkpf
      WHERE bukrs = @lt_bkpf-bukrs
        AND belnr = @lt_bkpf-belnr
        AND gjahr = @lt_bkpf-gjahr
      INTO CORRESPONDING FIELDS OF TABLE @lt_with.

    " C) Terceros
    SELECT lifnr, name1, stcd1, land1, pstlz
      FROM lfa1
      FOR ALL ENTRIES IN @lt_bseg
      WHERE lifnr = @lt_bseg-lifnr
        AND lifnr <> @space
      INTO CORRESPONDING FIELDS OF TABLE @lt_lfa1.

    SELECT kunnr, name1, stcd1, land1, pstlz
      FROM kna1
      FOR ALL ENTRIES IN @lt_bseg
      WHERE kunnr = @lt_bseg-kunnr
        AND kunnr <> @space
      INTO CORRESPONDING FIELDS OF TABLE @lt_kna1.

    " D) El folio fiscal se lee aparte (fill_folio)

*----------------------------------------------------------------------*
* 5. Armado de la salida (get_table_alv)
*----------------------------------------------------------------------*
    LOOP AT lt_bseg ASSIGNING FIELD-SYMBOL(<ls_bseg>).
      CLEAR ls_row.

      " Posición (insert_bseg)
      ls_row-sociedad          = <ls_bseg>-bukrs.
      ls_row-ejercicio         = <ls_bseg>-gjahr.
      ls_row-numerodocumento   = <ls_bseg>-belnr.
      ls_row-posicion          = <ls_bseg>-buzei.
      ls_row-doccompensacion   = <ls_bseg>-augbl.
      ls_row-fechacompensacion = <ls_bseg>-augdt.
      ls_row-importemd         = <ls_bseg>-wrbtr.
      ls_row-importeml         = <ls_bseg>-dmbtr.
      ls_row-indicadoriva      = <ls_bseg>-mwskz.
      ls_row-texto             = <ls_bseg>-sgtxt.

      " Cabecera (insert_bkpf)
      READ TABLE lt_bkpf ASSIGNING FIELD-SYMBOL(<ls_bkpf>)
           WITH TABLE KEY bukrs = <ls_bseg>-bukrs
                          belnr = <ls_bseg>-belnr
                          gjahr = <ls_bseg>-gjahr.
      IF sy-subrc = 0.
        ls_row-clasedocumento       = <ls_bkpf>-blart.
        ls_row-fechadocumento       = <ls_bkpf>-bldat.
        ls_row-fechacontabilizacion = <ls_bkpf>-budat.
        ls_row-periodo              = <ls_bkpf>-monat.
        ls_row-referencia           = <ls_bkpf>-xblnr.
        ls_row-monedamd             = <ls_bkpf>-waers.
        ls_row-usuarioregistro      = <ls_bkpf>-usnam.
      ENDIF.

      " Moneda local (necesaria para la semántica de ImporteML)
      READ TABLE lt_t001 ASSIGNING FIELD-SYMBOL(<ls_t001>)
           WITH TABLE KEY bukrs = <ls_bseg>-bukrs.
      IF sy-subrc = 0.
        ls_row-monedaml = <ls_t001>-waers.
      ENDIF.

      " Gasto (insert_bseg_gasto): se queda la última línea 5* del documento
      LOOP AT lt_gasto ASSIGNING FIELD-SYMBOL(<ls_gasto>)
           WHERE bukrs = <ls_bseg>-bukrs
             AND belnr = <ls_bseg>-belnr
             AND gjahr = <ls_bseg>-gjahr.
        ls_row-cuentagasto = <ls_gasto>-hkont.
        ls_row-ceco        = <ls_gasto>-kostl.
      ENDLOOP.

      " Impuestos (insert_bset): suma a nivel documento; con '**' todos los indicadores
      LOOP AT lt_bset ASSIGNING FIELD-SYMBOL(<ls_bset>)
           WHERE bukrs = <ls_bseg>-bukrs
             AND belnr = <ls_bseg>-belnr
             AND gjahr = <ls_bseg>-gjahr
             AND fwste IS NOT INITIAL.
        IF <ls_bseg>-mwskz <> '**' AND <ls_bset>-mwskz <> <ls_bseg>-mwskz.
          CONTINUE.
        ENDIF.
        ls_row-importeiva = ls_row-importeiva + <ls_bset>-fwste.
        IF <ls_bset>-hkont IS NOT INITIAL.
          ls_row-cuentaiva = <ls_bset>-hkont.
        ENDIF.
      ENDLOOP.

      " Retenciones (insert_with_item): por posición
      LOOP AT lt_with ASSIGNING FIELD-SYMBOL(<ls_with>)
           WHERE bukrs = <ls_bseg>-bukrs
             AND belnr = <ls_bseg>-belnr
             AND gjahr = <ls_bseg>-gjahr
             AND buzei = <ls_bseg>-buzei
             AND wt_qbshb IS NOT INITIAL.
        ls_row-retenciones = ls_row-retenciones + <ls_with>-wt_qbshb.
      ENDLOOP.

      " Terceros (insert_tercero_data)
      IF <ls_bseg>-lifnr IS NOT INITIAL.
        ls_row-acreedor = <ls_bseg>-lifnr.
        READ TABLE lt_lfa1 ASSIGNING FIELD-SYMBOL(<ls_lfa1>)
             WITH TABLE KEY lifnr = <ls_bseg>-lifnr.
        IF sy-subrc = 0.
          ls_row-nombretercero = <ls_lfa1>-name1.
          ls_row-niftercero    = <ls_lfa1>-stcd1.
          ls_row-paistercero   = <ls_lfa1>-land1.
          ls_row-cptercero     = <ls_lfa1>-pstlz.
        ENDIF.
      ELSEIF <ls_bseg>-kunnr IS NOT INITIAL.
        ls_row-cliente = <ls_bseg>-kunnr.
        READ TABLE lt_kna1 ASSIGNING FIELD-SYMBOL(<ls_kna1>)
             WITH TABLE KEY kunnr = <ls_bseg>-kunnr.
        IF sy-subrc = 0.
          ls_row-nombretercero = <ls_kna1>-name1.
          ls_row-niftercero    = <ls_kna1>-stcd1.
          ls_row-paistercero   = <ls_kna1>-land1.
          ls_row-cptercero     = <ls_kna1>-pstlz.
        ENDIF.
      ENDIF.

      APPEND ls_row TO rt_rows.
    ENDLOOP.
  ENDMETHOD.


  METHOD fill_folio.
    TYPES: BEGIN OF ty_folio,
             tdname TYPE tdobname,
             folio  TYPE ty_row-nuevofoliofiscal,
           END OF ty_folio.

    DATA: lt_names  TYPE SORTED TABLE OF tdobname WITH UNIQUE KEY table_line,
          lt_folios TYPE HASHED TABLE OF ty_folio WITH UNIQUE KEY tdname,
          lt_lines  TYPE STANDARD TABLE OF tline,
          lv_folio  TYPE string,
          lv_name   TYPE tdobname.

    " Nombre del texto: BUKRS + BELNR + GJAHR (igual que el CONCATENATE del reporte)
    LOOP AT ct_rows ASSIGNING FIELD-SYMBOL(<ls_row>).
      lv_name = |{ <ls_row>-sociedad }{ <ls_row>-numerodocumento }{ <ls_row>-ejercicio }|.
      INSERT lv_name INTO TABLE lt_names.
    ENDLOOP.

    IF lt_names IS INITIAL.
      RETURN.
    ENDIF.

    " Solo se llama READ_TEXT para los documentos que tienen el texto (get_stxh)
    SELECT tdname
      FROM stxh
      FOR ALL ENTRIES IN @lt_names
      WHERE tdobject = 'BELEG'
        AND tdname   = @lt_names-table_line
        AND tdid     = 'YUUD'
        AND tdspras  = @sy-langu
      INTO TABLE @DATA(lt_stxh).

    LOOP AT lt_stxh INTO DATA(ls_stxh).
      CLEAR: lt_lines, lv_folio.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id       = 'YUUD'
          language = sy-langu
          name     = ls_stxh-tdname
          object   = 'BELEG'
        TABLES
          lines    = lt_lines
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      LOOP AT lt_lines INTO DATA(ls_line).
        IF lv_folio IS INITIAL.
          lv_folio = ls_line-tdline.
        ELSE.
          lv_folio = |{ lv_folio } { ls_line-tdline }|.
        ENDIF.
      ENDLOOP.

      INSERT VALUE #( tdname = ls_stxh-tdname folio = lv_folio ) INTO TABLE lt_folios.
    ENDLOOP.

    LOOP AT ct_rows ASSIGNING <ls_row>.
      lv_name = |{ <ls_row>-sociedad }{ <ls_row>-numerodocumento }{ <ls_row>-ejercicio }|.
      READ TABLE lt_folios ASSIGNING FIELD-SYMBOL(<ls_folio>)
           WITH TABLE KEY tdname = lv_name.
      IF sy-subrc = 0.
        <ls_row>-nuevofoliofiscal = <ls_folio>-folio.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD apply_filters.
    FIELD-SYMBOLS: <ls_row>   TYPE ty_row,
                   <lv_value> TYPE any.

    DATA: lv_tabix TYPE sy-tabix,
          lv_folio TYPE string,
          lt_range TYPE if_rap_query_filter=>tt_range_option.

    " Estos ya se aplicaron en la selección a BD tal como en el reporte.
    " Acreedor/Cliente NO se vuelven a aplicar por línea para replicar el original.
    DATA(lt_db_fields) = VALUE string_table( ( `SOCIEDAD` )
                                             ( `EJERCICIO` )
                                             ( `FECHACONTABILIZACION` )
                                             ( `NUMERODOCUMENTO` )
                                             ( `REFERENCIA` )
                                             ( `ACREEDOR` )
                                             ( `CLIENTE` ) ).

    LOOP AT it_filters INTO DATA(ls_filter).
      IF line_exists( lt_db_fields[ table_line = ls_filter-name ] ).
        CONTINUE.
      ENDIF.

      lt_range = ls_filter-range.

      IF ls_filter-name = c_folio_field.
        " Folio: sin distinguir mayúsculas/minúsculas
        LOOP AT lt_range ASSIGNING FIELD-SYMBOL(<ls_range>).
          <ls_range>-low  = to_upper( <ls_range>-low ).
          <ls_range>-high = to_upper( <ls_range>-high ).
        ENDLOOP.

        LOOP AT ct_rows ASSIGNING <ls_row>.
          lv_tabix = sy-tabix.
          lv_folio = to_upper( <ls_row>-nuevofoliofiscal ).
          IF lv_folio NOT IN lt_range.
            DELETE ct_rows INDEX lv_tabix.
          ENDIF.
        ENDLOOP.

      ELSE.
        " Cualquier otro filtro que el usuario agregue desde "Adaptar filtros"
        LOOP AT ct_rows ASSIGNING <ls_row>.
          lv_tabix = sy-tabix.
          ASSIGN COMPONENT ls_filter-name OF STRUCTURE <ls_row> TO <lv_value>.
          IF sy-subrc = 0 AND <lv_value> NOT IN lt_range.
            DELETE ct_rows INDEX lv_tabix.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
