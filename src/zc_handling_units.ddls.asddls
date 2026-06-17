@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Handling Unit - Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI: {
    headerInfo: {
        typeName: 'Hadndling Unit',
        typeNamePlural: 'Handling Units',
        title: { type: #STANDARD, value: 'HandlingUnitNumber' }
    }
}
define view entity zc_handling_units
  as projection on zi_handling_unit as HandlingUnt
{
  key HandlingUnitNumber,
      ExternalHandlingUnitID,
      HandlingUnitDescription,
      PackagingMaterial,
      PackingObject,
      HUObject,
      @Semantics.quantity.unitOfMeasure: 'WeightUnit'
      GrossWeight,
      WeightUnit,
      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      Volume,
      VolumeUnit,
      @Semantics.quantity.unitOfMeasure: 'VolumeUnit'
      TareWeight,
      // DeliveryNumber,
      // DeliveryItem,
      // Material,
      // @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      // Quantity,
      // QuantityUnit,
      /* Associations */
      _Delivery : redirected to parent zc_outbound_delivery,
      _Item: redirected to composition child zc_handling_unit_item
}
