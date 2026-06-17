@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Handling Unit Item - Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity zi_handling_unit_item
  as select from vepo
  association to parent zi_handling_unit as _HandlingUnit on $projection.HandlingUnitNumber = _HandlingUnit.HandlingUnitNumber
{
  key vepo.venum as HandlingUnitNumber,
  key vepo.vepos as HandlingUnitItemNumber,
      vepo.vbeln as DeliveryNumber,
      vepo.posnr as DeliveryItem,
      vepo.matnr as Material,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      vepo.vemng as Quantity,
      vepo.vemeh as QuantityUnit,

      _HandlingUnit // Make association public
}
