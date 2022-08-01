
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tyron Moodley
-- Create date: <Create Date>
-- Description:	<Description>
-- =============================================
CREATE PROCEDURE dbo.pr_GetOrderSummary 

 @StartDate date ,
 @EndDate date ,
 @EmployeeId nvarchar(255) = NULL,
 @CustomerId nvarchar(255) = NULL

AS
BEGIN

	SET NOCOUNT ON;


;with cte_employeedetails as (
select 
emp.EmployeeID,
cus.CustomerID,
emp.TitleOfCourtesy + ' ' + emp.FirstName + ' ' + emp.LastName as [EmployeeFullName],
sh.CompanyName as [Shipper CompanyName],
cus.CompanyName as [Customer CompanyName],
oo.OrderDate,
sum(oo.Freight) as TotalFreightCost
from 
dbo.Orders oo
INNER JOIN dbo.Employees emp
on emp.EmployeeID = oo.EmployeeID
INNER JOIN dbo.Shippers sh
on oo.ShipVia = sh.ShipperID
INNER JOIN dbo.Customers cus
on oo.CustomerID = cus.CustomerID
where (@CustomerId is null or cus.CustomerID = @CustomerId)
AND (@EmployeeId is null or emp.EmployeeID = @EmployeeId)
AND oo.OrderDate BETWEEN @StartDate AND @EndDate
group by emp.EmployeeID , 
         cus.CustomerID , 
         sh.CompanyName, 
         cus.CompanyName, 
         oo.OrderDate , 
         emp.TitleOfCourtesy , 
         emp.FirstName , 
         emp.LastName
),
cte_order_details as 
(
  select 
  ord.*,
  od.ProductID,
  case
  when od.Discount = 0
  then od.UnitPrice * od.Quantity
  else
  (od.UnitPrice * od.Quantity) * (1 - (od.Discount))
  end as TotalOrderValue
  from 
  (
      select
      cte.*,
      oo.OrderID
      from 
      cte_employeedetails cte 
      join dbo.Orders oo
      on oo.EmployeeID = cte.EmployeeID
      and oo.CustomerID = cte.CustomerID
      and oo.OrderDate = cte.OrderDate
  ) as ord
  join dbo.[Order Details] od
  on ord.OrderID = od.OrderID
)
 select
 empd.EmployeeFullName,
 empd.[Shipper CompanyName],
 empd.[Customer CompanyName],
 empd.OrderDate as [Date],
 count(distinct cte2.OrderID) as NumberOfOrders, 
 empd.TotalFreightCost,
 count(distinct cte2.ProductID) as NumberOfDifferentProducts,
 cast(sum(cte2.totalOrderValue)as decimal(18,2)) as TotalOrderValue
 from  
 cte_employeedetails empd
 join cte_order_details cte2
 on empd.CustomerID = cte2.CustomerID
 and empd.EmployeeID = cte2.EmployeeID
 and empd.OrderDate = cte2.OrderDate
 group by empd.EmployeeID ,
          empd.CustomerID , 
          empd.EmployeeFullName , 
          empd.[Shipper CompanyName] ,
          empd.[Customer CompanyName] , 
          empd.OrderDate ,
          empd.TotalFreightCost
 order by empd.OrderDate

END
GO