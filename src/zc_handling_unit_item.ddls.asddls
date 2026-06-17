@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Handling Unit Item - Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@UI: {
    headerInfo: {
        typeName: 'Handling Unit Item',
        typeNamePlural : 'Handling Unit Items',
        title: { type: #STANDARD, value: 'Material' }
    }
}
define view entity zc_handling_unit_item
  as projection on zi_handling_unit_item as _HandlingUnitItem
{
  key HandlingUnitNumber,
  key HandlingUnitItemNumber,
      DeliveryNumber,
      DeliveryItem,
      Material,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit' 
      Quantity,
      QuantityUnit,
      /* Associations */
      _HandlingUnit : redirected to parent zc_handling_units
}
