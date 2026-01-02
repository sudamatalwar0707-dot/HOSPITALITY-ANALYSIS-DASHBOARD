create database Hospitality_Analysis;

use Hospitality_Analysis;

Alter table fact_aggregated_bookings add column occupancy_Rate_In_Parcentage decimal(10,1);

update fact_aggregated_bookings set occupancy_Rate_In_Parcentage = round((successful_bookings / capacity)*100,1);

# To verify all the KPI values in the dashbord 

select concat('₹',round(sum(revenue_generated)/1000000000,1), 'B') as Revenue_Genrated,
Concat('₹',round(sum(revenue_realized)/1000000000,1), 'B') as Realized_Revenue,
concat(round(count(distinct customer_id)/1000),'K') as Total_Customers,
concat(round(count(distinct booking_id)/1000),'K') as Total_Booking_Orders,
concat(round(sum(no_guests)/1000),'K') as Total_Guest_Visited,
concat('₹',round(avg(discount_applied),1)) as Average_Discount_Per_Order,
round(avg(customer_age)) as Average_Age_of_The_Customers,
concat(round(sum(case when booking_status = 'Cancelled' then 1 else 0 end) / count(distinct booking_id)* 100,1),'%') as Cancellation_Rate,
concat(round(sum(case when booking_status = 'Checked out' then 1 else 0 end) / count(distinct booking_id)* 100,1),'%') as Checkedout_Rate,
concat(round(sum(case when booking_status = 'No Show' then 1 else 0 end) / count(distinct booking_id)* 100,1),'%') as No_Show_Rate,
concat(round(avg(case when ratings_given > 0 then ratings_given end),1),'%') as Ratings_Given_By_Customers
from fact_bookings;

# Overview Analysis of Occupancy rate, Checked out rate, Cancellation Rate, No Show rate

 -- To calculate Occupancy Rate, Total Room Capacity, successful bookings

Select concat(round(avg(occupancy_Rate_In_Parcentage),1),'%') as Occupancy_Rate,
concat(round(sum(capacity)/1000),'K') as Total_Room_Capacity,
concat(round(sum(successful_bookings)/1000),'K') as Successful_Bookings 
from fact_aggregated_bookings;

-- To Calculate the Checked out rate in percentage, Total Checked out Bookings & Total Bookings, 

select concat(round(sum(case when booking_status="Checked out" then 1 else 0 end)* 100 / count(distinct booking_id)),"%") as Checked_Out_Rate,
concat(round(sum(case when booking_status="Checked out" then 1 else 0 end)/1000,1),"K") as Total_Checked_Out_Bookings,
concat(round(count(distinct booking_id)/1000),'K') as Total_Bookings
from fact_bookings;

-- To Calculate the Cancelletion rate in percentage, Total Cancelled Bookings & Total Bookings, 

select concat(round(sum(case when booking_status="Cancelled" then 1 else 0 end)* 100 / count(distinct booking_id),1),"%") as Cancelletion_Rate ,
concat(round(sum(case when booking_status="Cancelled" then 1 else 0 end)/1000,1),"K") as Cancelled_Bookings,
concat(round(count(distinct booking_id)/1000),'K') as Total_Bookings
from fact_bookings;

-- To Calculate the NO show rate in percentage, Total No Show Bookings & Total Bookings, 

select concat(round(sum(case when booking_status="No Show" then 1 else 0 end)* 100 / count(distinct booking_id)),"%") as No_Show_Rate ,
concat(round(sum(case when booking_status="No Show" then 1 else 0 end)/1000,1),"K") as No_Show_Bookings,
concat(round(count(distinct booking_id)/1000),'K') as Total_Bookings
from fact_bookings;

-- Loyalty Analysis with Customers

select is_loyalty_member, concat(round(count(distinct customer_id)/1000,1),'K') as Total_Customers from fact_bookings
group by is_loyalty_member
order by Total_Customers desc;

-- Day Type analysis with Revenue Generated with percentage

Select day_Type, concat('₹',round(sum(revenue_generated)/1000000),'M') as Total_Revenue_Genrated, 
concat(round(sum(revenue_generated)* 100/ (select sum(revenue_generated) from 
fact_bookings),1),'%') as Revenue_Genrated_In_Percentage from fact_bookings
group by day_type
order by Revenue_Genrated_In_Percentage desc;

-- Spacial Request Customers Analysis with Percentage

select  special_requests, concat(round(count(distinct customer_id)/1000,1),'K') as Total_Customers_In_Thausand,
concat(round(count(distinct customer_id) * 100/ (Select count(distinct customer_id) from 
fact_bookings),1),'%') As Total_Customers_In_Percentage from fact_bookings
group by special_requests
order by Total_Customers_In_Thausand desc;

-- Payment Methode Analysis

select payment_method,concat('₹', round(sum(revenue_generated)/1000000,1),'M') as Revenue, 
concat(round(count(distinct customer_id)/1000,1),'K') as Total_Customers
from fact_bookings join dim_hotels on fact_bookings.property_id = dim_hotels.property_id
group by payment_method
order by payment_method desc;

-- Category details 

select coalesce(category,'Grand total') as category,
concat('₹', round(sum(revenue_generated)/1000000,1),'M') as Revenue,
concat(round(count(distinct booking_id)/1000,1),'K') as Total_Bookings 
from fact_bookings join dim_hotels on fact_bookings.property_id = dim_hotels.property_id
group by category with rollup;

-- Proparty Details with using Stored Procedure 

DELIMITER //
Create procedure Get_Proparty_Details()
begin 
	select 
		property_name, concat(round(sum(no_guests)/1000),'K') as No_of_Guest_Visited, 
		concat('₹',round(sum(revenue_generated)/1000000,1),'M') as Revenue_Genrated,
		concat(round(count(distinct booking_id)/1000,1),'K') as Total_Bookings,
		concat('₹',round(sum(discount_applied)/1000000,1),'M') As Total_Discount,
		concat(round(avg(case when ratings_given > 0 then ratings_given end),1),'%') as Average_Ratings_Given_By_Customers 
		from fact_bookings join dim_hotels on fact_bookings.property_id = dim_hotels.property_id
	group by property_name
    order by Revenue_Genrated desc;
    
    select room_class, Concat(round(sum(no_guests)/1000),'k') as No_of_Guest_Visited_Thousands,
    concat(round(sum(revenue_generated)/1000000,1),'M') as Revenue_Genrated, 
    concat(round(count(distinct booking_id)/1000,1),'K') as Total_Bookings,
    concat(round(sum(discount_applied)/1000000,1),'M') As Total_Discount,
     concat(round(avg(case when ratings_given > 0 then ratings_given end),1),'%') as Average_Ratings_Given_By_Customers
    from fact_bookings join dim_rooms on fact_bookings.room_category = dim_rooms.room_id
    group by room_class
    order by Revenue_Genrated desc;
end //
    
    call Get_Proparty_Details();

# Booking Details using Stored procedure

DELIMITER //
Create procedure Get_Booking_Details()
begin
	Select 
		booking_channel, 
        concat(round(count(distinct booking_id)/1000),'K') as Total_bookings,
        concat(round(count(distinct booking_id) * 100/ (select count(distinct booking_id) from fact_bookings),1),'%') as Bookings_Percentage,
		concat('₹',round(sum(revenue_generated)/1000000),'M') as Revenue_Genrated,
        concat(round(sum(revenue_generated) * 100/ (Select sum(revenue_generated) from fact_bookings),1),'%') as Revenue_Percentage,
		concat(round(count(distinct customer_id)/1000),'K') as Total_Customers,
        concat(round(count(distinct customer_id) * 100/ (Select count(distinct customer_id) from fact_bookings),1),'%') as Customers_Percentage
	from fact_bookings
    group by booking_channel
    order by Bookings_Percentage desc;
    
    Select 
		booking_status,
		concat(round(count(distinct booking_id)/1000),'K') as Total_Bookings,
        concat(round(count(distinct booking_id)* 100/ (select count(distinct booking_id) from fact_bookings),1),'%') as Bookings_Percentage,
		concat('₹',round(sum(revenue_generated)/1000000),'M') as Revenue_Genrated,
        concat(round(sum(revenue_generated)* 100/ (select sum(revenue_generated) from fact_bookings),1),'%') as Revenue_Percentage 
	from fact_bookings
    Group by booking_status
    order by Bookings_Percentage desc;
    
    Select 
		booking_platform, 
        concat( round(count(distinct booking_id)/1000), 'K') as Total_bookings,
        concat(round(count(distinct booking_id) * 100/ (select count(distinct booking_id) from fact_bookings),1),'%') as Bookings_Percentage,
		concat('₹',round(sum(revenue_generated)/1000000),'M') as Revenue_Genrated,
        concat(round(sum(revenue_generated) * 100/ (Select sum(revenue_generated) from fact_bookings),1),'%') as Revenue_Percentage ,
		concat(round(count(distinct customer_id)/1000),'K') as Total_Customers,
        concat(round(count(distinct customer_id) * 100/ (Select count(distinct customer_id) from fact_bookings),1),'%') as Customers_Percentage
	from fact_bookings
    group by booking_platform
    order by Bookings_Percentage desc;
end //

    call Get_Booking_Details();

# Geographical Details using Stored Procedure

DELIMITER //
Create procedure Get_Geographical_Details()
	begin
		Select country, concat('₹',round(sum(revenue_generated)/1000000),'M') as Revenue_Genrated,
                concat(round(sum(revenue_generated) * 100/ (Select sum(revenue_generated) from fact_bookings),1),'%') as Revenue_Percentage ,
		concat(round(count(distinct customer_id)/1000),'K') as Total_Customers,
				concat(round(count(distinct customer_id) * 100/ (Select count(distinct customer_id) from fact_bookings),1),'%') as Customers_Percentage,
		concat( round(count(distinct booking_id)/1000), 'K') as Total_bookings,
		        concat(round(count(distinct booking_id) * 100/ (select count(distinct booking_id) from fact_bookings),1),'%') as Bookings_Percentage
	from fact_bookings
    Group by country
    order by Revenue_Genrated desc;
    
		select city, concat('₹',round(sum(revenue_generated)/1000000),'M') as Revenue_Genrated,
                concat(round(sum(revenue_generated) * 100/ (Select sum(revenue_generated) from fact_bookings),1),'%') as Revenue_Percentage ,
		concat(round(count(distinct customer_id)/1000),'K') as Total_Customers,
				concat(round(count(distinct customer_id) * 100/ (Select count(distinct customer_id) from fact_bookings),1),'%') as Customers_Percentage,
		concat( round(count(distinct booking_id)/1000), 'K') as Total_bookings,
		        concat(round(count(distinct booking_id) * 100/ (select count(distinct booking_id) from fact_bookings),1),'%') as Bookings_Percentage
		from fact_bookings join dim_hotels on fact_bookings.property_id = dim_hotels.property_id
		Group by city
		order by Revenue_Genrated desc;
  end //  

call Get_Booking_Details();

# create view for payment_details

create view payment_Details as 
	Select payment_method,  
		concat('₹',round(sum(revenue_generated)/1000000,1),'M') as Revenue_Genrated,
        Concat('₹',round(sum(revenue_realized)/1000000,1),'M') as Realized_Revenue,
        concat(round(count(distinct booking_id)/1000,1),'K') as Total_Booking_Order
        from fact_bookings
        group by payment_method
        order by Revenue_Genrated;
        
Select * From payment_Details;













