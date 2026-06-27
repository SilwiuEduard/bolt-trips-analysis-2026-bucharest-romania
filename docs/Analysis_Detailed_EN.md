Analysis Q01: General Indicators of Actual Trips
Based on the data from Q01_Calcul_viteza_medie_curse.csv, I extracted the average parameters of my field activity:
• Distance and duration: The average of a completed trip is 6.1 km traveled in an average time of 15.7 minutes.
• Speed and pickup: The general average speed during trips is 23.5 km/h, and the average distance traveled to the client (to_client_dist_km) is 1.10 km, performed in an average time of 3.1 minutes (to_client_dur_min).

Analysis Q02: Average Speed Profile by Hours
The data from Q02_Calcul_viteza_medie_pe_ore.csv shows the variations in speed and volume throughout the 24 hours:
• Daytime operational bottleneck (Hours 07:00 - 17:00): Speed drops to the absolute minimum of 14.4 km/h at 07:00, remains at 15.4 km/h at 08:00, and stagnates around 17-18 km/h at noon. The number of completed trips in this interval is reduced (between 4 and 50 cumulative trips per hour in history).
• Volume and fluidization window (Hours 18:00 - 23:00): Speed increases constantly from 20.6 km/h (18:00) up to 28.6 km/h (23:00). This interval also concentrates the highest volume of orders in history, with peaks of 155 trips (19:00), 147 trips (20:00), and 189 trips (21:00).
• Night regime (Hours 00:00 - 04:00): Offers high running speeds, from 27.9 km/h at midnight to a peak of 38.8 km/h at 03:00, but on a much smaller total volume of trips.

Analysis Q03: Average Speed Profile by Days of the Week
The file Q03_Calcul_viteza_medie_pe_zile.csv highlights travel efficiency depending on the day of the week:
• The slowest days: Thursday records the lowest average speed, of 20.2 km/h (with 217 trips), followed by Friday with 21.4 km/h (194 trips) and Wednesday with 22.2 km/h (193 trips).
• The fastest days: Sunday offers the highest fluidity, with an average speed of 26.4 km/h (160 trips), followed by Saturday with 25.6 km/h (180 trips) and the days of Monday and Tuesday, both having an average of 25.1 km/h.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• Concentrate activity in the 18:00 - 23:00 interval: The figures from Q4 show that this is the ideal area. The huge volume of trips (over 110-180 trips per interval) guarantees me consecutive orders without dead times, while the speed increases above 20-25 km/h, allowing me to finish trips quickly and gather the 2000-2500 LEI without exceeding 40 hours per week.
• Prioritize the weekend (Saturday and Sunday) and the beginning of the week (Monday-Tuesday): The data from Q03 shows that on these days the average speed is the highest (between 25.1 and 26.4 km/h). Driving on these days optimizes fuel consumption and shortens trip durations.

What I DO NOT do to avoid unproductive times:
• Avoid the 07:00 - 16:00 hourly interval during the week: Running at speeds of 14-17 km/h (Q4) physically limits the number of trips I can make in an hour. Driving in this interval would force me to stay in the car well over the 40 weekly hours to reach my money target, adding severe wear to the DSG gearbox in stop-and-go regime.
• Reduce presence in traffic on Thursdays and Fridays during busy hours: Q03 shows that Thursday and Friday are the most congested days of the week (20.2 - 21.4 km/h). On these days, I avoid going out to drive before the evening traffic clears up (18:00).

Analysis Q04, Q05, and Q06: Financial Efficiency per Kilometer and Minute (Grouped by Hours and Days)
In this analysis, I evaluated the direct profitability indicators of the trips, tracking the evolution of the medie_lei_per_minut and medie_lei_per_km indicators. The goal is to identify with mathematical precision the ideal windows in which the time spent at the wheel generates maximum revenues per unit of time, minimizing car wear relative to the generated income.

Analysis Q04: Financial Profitability by Hours
The data from Q04_medie_lei_km_si_min_pe_ore.csv shows clear variations in performance depending on the time of day:
• Collapse of daytime efficiency (Hours 10:00 - 15:00): This is the most unprofitable interval. The earnings value reaches a critical minimum of 0.8 LEI / minute (11:00) and remains at 0.9 - 1.0 LEI / minute for the rest of the afternoon. Although the revenue per kilometer seems stable (between 2.5 and 3.4 LEI / km), the low speed in traffic lengthens trips and drastically reduces income per minute.
• Evening stabilization (Hours 18:00 - 22:00): With the increase in demand, financial efficiency rises to 1.3 - 1.4 LEI / minute, maintaining a high revenue per distance of 3.3 - 4.3 LEI / km.
• Nighttime efficiency peak (Hours 23:00 - 03:00): As the streets clear up, profitability per minute increases significantly: 1.5 LEI / minute at 23:00, 1.6 LEI / minute at midnight, and an absolute peak of 2.3 LEI / minute at 03:00.

Analysis Q05: Financial Profitability by Days of the Week
The file Q05_medie_lei_km_si_min_pe_zile.csv highlights the macro performance throughout the week:
• Working days (Monday - Friday): Present a linear and reduced efficiency over time, stagnating at 1.2 - 1.3 LEI / minute. On Thursdays and Fridays, revenue per kilometer increases to 3.7 LEI / km, reflecting more frequent dynamic rates due to congestion.
• The weekend (Saturday - Sunday): Represents the most profitable full days, offering a stable average of 1.5 LEI / minute, against the background of a lower number of drivers, more fluid traffic, and excellent revenue per distance (3.6 - 3.7 LEI / km).

Analysis Q06: Intersection between Days and Hours (Financial Hotspots)
By simultaneously correlating days with hours in Q06_medie_lei_km_si_min_pe_zile_si_ore.csv, I discovered the specific intervals of maximum performance (with relevant trip volumes):
• Top Sunday Night/Morning (Hours 00:00 - 03:00): Sunday at 03:00 delivers a peak of 2.3 LEI / minute (3.7 LEI / km), and at hours 00:00 - 02:00 performance stays between 1.6 and 2.1 LEI / minute, also having a massive revenue per distance (up to 5.0 LEI / km).
• Top Saturday (Hours 23:00 - 00:00): Generates 1.6 - 2.1 LEI / minute and an exceptional indicator of 3.7 - 5.0 LEI / km.
• Weekday peaks: Friday evening at 18:00 stands out with 1.6 LEI / minute and a high level of 4.6 LEI / km (effect of weekend dynamic rates), and Thursday at 23:00 reaches 1.9 LEI / minute.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• Prioritize weekend windows and productive nights: To reach the target of 2000-2500 LEI in under 40 hours, I must capitalize on the intervals that pay the driving time best. Activating the application Friday and Saturday night (the 22:00 - 02:00 interval) and early Sunday morning guarantees me a yield of over 1.6 - 2.1 LEI per minute. In an actual driving rhythm, this means a potential of over 100 LEI / hour, massively shortening the work week.
• Go out to drive during the week only after 18:00: The data from Q04 shows that only from this hour does the yield jump to 1.4 LEI / minute, also benefiting from the highest historical total revenues.

What I DO NOT do to avoid unproductive times:
• Do not work in the 10:00 - 15:00 hourly interval: The figures from Q04 are incontestable: driving for 0.8 - 0.9 LEI / minute means accepting an inefficient rhythm. Working in this interval, I would be stuck in the car well over 40 hours to reach the objective, unnecessarily increasing car wear and fuel consumption relative to the collected money.
• Do not neglect the weekend in favor of mid-week days: Q05 demonstrates that Saturday and Sunday bring ~20% more money for each minute of trip than a Thursday or Wednesday. Concentrating the effort on the weekend decreases the operational pressure during the week.

Analysis Q07: Top 20 Hourly Intervals of the Week by Net Earnings per Hour
In this analysis, I classified and ranked the 20 most profitable specific hourly windows of the entire week, ordered strictly by the net earnings generated per hour (castig_net_ora_lei). This analysis gives me the exact map of maximum productivity, eliminating guesswork and showing me the exact moments when the market pays best for the time spent at the wheel, ensuring the achievement of the 2000-2500 LEI/week target in a minimum number of hours.
Key Figures Identified (From raw data Q07)
• Ultra-Profitable Elite Zone (Earnings > 85 LEI / hour):
• Sunday morning (Hours 02:00 - 04:00): Represents the absolute peak of the week. The 02:00 hourly interval brings a record of 112.6 LEI / hour, being followed immediately by the 03:00 interval with 100.4 LEI / hour.
• Saturday night (Hour 00:00): Opens the elite weekend with 87.9 LEI / hour.
• Constant High Performance Zone (Earnings between 70 - 80 LEI / hour):
• Sunday (Hours 00:00 and 22:00): Delivers 79.6 LEI / hour, respectively 79.2 LEI / hour, on excellent trip volumes (up to 24 trips in history).
• Saturday evening (Hours 22:00 - 23:00): Maintains a solid rhythm of 75.6 - 75.7 LEI / hour (cumulative revenues of over 1300 LEI only in these two windows).
• Friday evening and Tuesday: Friday at 20:00 (74.8 LEI / hour) and 18:00 (71.9 LEI / hour), along with a very profitable anomaly on Tuesday at 23:00 (73.4 LEI / hour) and 18:00 (71.1 LEI / hour).
• Base Zone for Volume (Earnings between 65 - 70 LEI / hour):
• Includes Friday nights (hours 22:00 - 23:00), but also weekday evenings: Monday at hours 18:00, 21:00, and 22:00 (with a volume peak of 35 trips at 21:00, generating 67.9 LEI / hour), along with Thursday at 18:00 (67.8 LEI / hour).

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• I build my "Compressed Work Week" around this Top 20: If I work exclusively in these elite hourly windows, the mathematics behind the data is simple: maintaining an average of ~75 LEI / hour from this table, I can reach the threshold of 2250 LEI in just 30 hours online. This leaves me a huge reserve up to the assumed limit of 40 hours.
• I am mandatory present on the route during the nocturnal weekend: Saturday to Sunday nights (hours 22:00 - 04:00) and Sunday evening are gold mines that must not be missed, being the intervals that forcibly raise the entire week's average due to dynamic rates and lack of traffic.
• Capitalize on "Evening Commute" type windows (Hours 18:00 - 21:00): Monday, Friday, and Thursday at 18:00 represent ideal moments to start the shift, catching the payment peak generated by people leaving offices.

What I DO NOT do to avoid unproductive times:
• Do not consume my energy outside this hourly ecosystem: Any hour worked outside productive hours (such as the dead afternoons analyzed in the previous tables) decreases the overall average earnings and forces me to stay longer at the wheel for the same money.
• Do not ignore good windows during the week (Tuesday/Monday evening): Although the weekend is the king of revenues, Monday (21:00) and Tuesday (23:00) evenings offer excellent yields of over 67-73 LEI / hour on safe trip volumes, being ideal for completing the weekly target without waiting only for Saturdays and Sundays.

Analysis Q08: Efficiency Segmentation Based on Trip Length
In this analysis, I classified completed trips into three distinct categories (Short, Medium, and Long) to evaluate how route distance influences the yield per minute, revenue per kilometer, and pickup effort. This segmentation helps me understand what type of trips directly support the objective of generating 2000-2500 LEI/week in under 40 hours, while protecting the vehicle from unnecessary wear.
Key Figures Identified (From raw data Q08)
• Short Trips (0 - 3 km): Although they represent a smaller volume (243 trips), they offer a remarkable financial efficiency. They generate the highest revenue over time, of 1.7 LEI / minute, and a record average revenue per distance, of 5.4 LEI / km. The average distance to the client is minimal (1.0 km).
• Medium Trips (3 - 8 km): Represent the core of my activity, with the highest volume (781 trips). Efficiency drops, however, to 1.2 LEI / minute and 3.2 LEI / km, having an average pickup distance of 1.1 km.
• Long Trips (over 8 km): Concentrate 282 trips. Performance over time stabilizes at 1.3 LEI / minute, but revenue per distance reaches the minimum value of 2.8 LEI / km. Pickup distance is the largest, on average 1.2 km.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• Prioritize and multiply Short Trips (0 - 3 km) in dense areas: The figures in the table are clear: short trips are the most profitable per unit of time (1.7 LEI / minute). To reach the money target compressing hours below the 40h threshold, I need this rapid revenue rhythm. Concentrating activity in areas where orders are placed for short distances (e.g., office centers, central or student areas) allows me to quickly link these high-yield orders.
• Accept Long Trips only if traffic is fluid: Long trips have a small revenue per kilometer (2.8 LEI / km). They become profitable for reaching the objective only at times when I can maintain a high speed (evening or weekends), so that I compensate for the low revenue per distance through a fast completion of the trip time.

What I DO NOT do to avoid unproductive times:
• Do not accept Long Trips in heavy traffic conditions: If I accept a trip of over 8 km at peak hours, the low revenue per distance (2.8 LEI / km) combined with traffic bottlenecks will collapse the lei/minute indicator and will add a massive and unjustified wear on the car (many kilometers traveled at a poor financial yield).
• Avoid long pickups for Medium and Long Trips: Since the pickup distance increases to 1.1 - 1.2 km for these categories, I avoid traveling long distances to pick up clients, as unpaid pickup kilometers directly dilute nominal revenue and increase operational costs.

Analysis Q09: Analysis of Distance Efficiency and Dead Kilometers by Hours
In this analysis, I evaluated the ratio between kilometers traveled empty for client pickup and actual paid trip kilometers, calculating the percentage impact of dead kilometers on each hourly interval. The purpose is to identify the hours that optimize fuel consumption and reduce unproductive running, to support the target of 2000-2500 LEI/week in under 40 hours worked.
Key Figures Identified (From raw data Q09)
• Peaks of inefficiency and dead kilometers (Percentage > 22%): \* The 05:00 interval records the highest level of dead kilometers, with a percentage of 44.5% (medie_km_preluare_gol of 1.8 km for a paid trip of only 2.2 km).
• The 07:00 interval follows with 29.6% dead kilometers, and the 02:00 interval has 26.8%.
• The 00:00 interval accumulates 22.0% dead kilometers at a volume of 64 trips.
• Maximum efficiency intervals (Percentage < 20%):
• The lowest percentages of dead kilometers appear in peak and transition intervals: hour 08:00 (19.7%), hour 01:00 (19.3%), hour 22:00 (18.5%), and the historical minimum at hour 21:00 with only 17.6% dead kilometers (1.0 km pickup for 5.9 km paid trip, on a massive volume of 189 trips).
•During midday, hour 14:00 maintains an optimal level of 17.3% dead kilometers.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• Prioritize the 21:00 - 22:00 hourly interval: Raw data shows that in this window the percentage of dead kilometers drops to the lowest level of the day (17.6% - 18.5%), while the trip volume is maximum (over 160-180 trips in history). This guarantees that I link trips almost instantly, reducing car wear and time consumed going empty towards clients.
• Focus activity on windows where the paid trip is long: At hours 22:00, 23:00, and 01:00, the average length of the paid trip jumps to 6.4 - 7.5 km, efficiently cushioning the distance traveled to the client.

What I DO NOT do to avoid unproductive times:
• Avoid activating the application at 05:00 or 07:00 in the morning: Figures clearly show that at these hours I travel very many kilometers empty compared to what I actually transport (up to 44.5% dead kilometers). This way of working increases my fuel cost and overall car wear, lowering real net profit per hour.
• Do not accept long pickups in windows with a history of short trips: If I activate at hours like 02:00 or 05:00, where the average paid trip is small (2.2 - 4.4 km), I ignore pickups that exceed the average of 1.5 - 1.8 empty km, so as not to work at an operational loss.

Analysis Q10: Online Time, Utilization Rate, and Net Earnings per Hour
In this analysis, I evaluated the daily dynamics of the total time spent online (timp_online_total) relative to the time I had an active trip (timp_cursa_activa), calculating the real utilization rate of working time (procent_utilizare). This analysis shows me how efficiently the algorithm "links" trips and how a high utilization rate translates directly into an increase in net earnings per hour (castig_net_ora_lei), being the key element to remain below the threshold of 40 hours worked per week.
Key Figures Identified (From raw data Q10)
• General daily average indicators: Over the 91 indexed days, I recorded an average of daily revenues of 322.69 LEI, with an average number of 14.3 completed trips per day. The general average net gain is 60.74 LEI / hour, supported by a very high daily average utilization rate of 84.7%.
• Peak performances (Utilization rate > 90%):
• The maximum utilization rate reached 97.3% on the date of 2026-04-30 (where out of 5h 10min online, 5h 02min were in active trip).
• Days with extreme utilization also generate the highest hourly earnings, as seen in the data from 2026-05-29: utilization of 95.1%, correlated with a record net gain of 92.6 LEI / hour (total revenue of 478.4 LEI in just 5h 10min online).
• Low efficiency days (Utilization rate < 72%):
• The historical minimum of utilization was 66.4% (2026-03-15), when out of 5h 06min online only 3h 23min were active. On this day of poor utilization, hourly earnings tend to decrease towards the threshold of 49.0 - 51.1 LEI / hour.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• I try to maintain a high utilization rate (over 85%): Data proves a clear linear correlation: when the utilization rate passes 85-90%, net earnings per hour constantly exceed the value of 65-75 LEI / hour (reaching on excellent days even over 90 LEI / hour). At such a performance, I can reach the weekly objective of 2000-2500 LEI working between 27 and 35 online hours, remaining well below the self-imposed limit of 40 hours.
• Optimize breaks and positioning: After completing a trip, I remain in place for 2-3 minutes or move exclusively towards areas with high density confirmed from previous analyses, to force the algorithm to allocate the next order to me immediately and keep dead time to a minimum.

What I DO NOT do to avoid unproductive times:
• Do not remain online inactive or in dead zones: If the utilization rate drops below 75%, figures show that efficiency per hour dangerous drops towards 37-49 LEI / hour. At this slow pace, I would be forced to work over 50 hours per week to reach the money target. If the market has no demand and the application stagnates in waiting state for more than 15 minutes, I turn off the online state to stop the useless wear of time and car.
• Do not dilute statistics: I avoid leaving the application turned on while solving personal problems or staying stationed for long periods without the intention of taking orders, ensuring that data reflects my real working productivity.

Analysis Q11: Weekly Evolution of Revenues, Worked Hours, and Yield
This macro analysis presents my operational evolution from the debut of the ridesharing activity until now, highlighting the correlation between total hours spent online, gross weekly revenues, hourly yield, and average occupancy degree. Historical data validates the optimization process: increasing efficiency allows me to constantly generate a stable income, reducing at the same time the effort and car wear.
Key Figures Identified (From raw data Q11)
• Debut and calibration phase (February - March):
•I started in the week of 23-Feb with a revenue of 1,440.8 LEI in 30.4 online hours (47.4 LEI / hour).
• In the week of 02-Mar I reached the largest volume of work in history: 48.0 online hours to generate 2,286.9 LEI at a yield of only 47.6 LEI / hour. Gradually, in the month of March, the hourly yield stabilized around the value of 50.2 - 52.6 LEI / hour.
• Optimization and growth phase (April):
• The hourly yield increased significantly, exceeding the threshold of 64.0 LEI / hour. A remarkable example is the week of 20-Apr, when I generated 2,404.6 LEI in just 37.6 online hours (64.0 LEI / hour), fitting perfectly into both assumed objectives.
• Maximum efficiency and maturity phase (May - June):
• I recorded a remarkable efficiency curve. In the week of 11-May I achieved 2,443.0 LEI in 34.3 hours (71.3 LEI / hour), and in the week of 25-May I reached the historical peak of yield: 2,460.6 LEI in only 30.7 online hours, meaning a record of 80.2 LEI / hour, supported by an excellent utilization of 84.6%.
• The most recent full week (01-Jun) keeps the same optimal direction: 1,682.4 LEI in just 23.7 online hours (71.1 LEI / hour).

Actionable Recommendations and Operational Strategy

What I do to maintain efficiency:
• I follow the operational model from May (The 30-35 hours strategy): Weekly data demonstrates that the most profitable periods (2400+ LEI) were achieved when I worked concentrated, between 30 and 35 online hours per week. This operational interval ensures a top financial yield (over 70-80 LEI / hour) and guarantees that I reach the proposed financial threshold, protecting personal time and keeping car wear under control.
• Base planning on a consolidated minimum yield of 65-70 LEI / hour: Given the maturity reached by the algorithm and accumulated experience, I know I can generate the threshold of 2000 LEI in approximately 28-30 hours of active presence in the application.

What I DO NOT do to avoid unproductive times:
• Do not return to the extended work model of over 40 hours: The week of 02-Mar (48 hours worked) is the clear example of inefficiency: the hours added extra were hours of poor quality (dead time, heavy traffic), which diluted the general yield to only 47.6 LEI / hour. Extended work increases fatigue and risk of incidents, without bringing a real financial benefit per unit of time.
• Do not panic in short or fragmented weeks: Weeks like those of 06-Apr or 27-Apr show lower gross revenues (just over 1000 LEI), but the hourly yield remained high (64.7, respectively 55.0 LEI / hour). This indicates that efficiency was good, but the allocated time was reduced for administrative or personal reasons, not being a decrease in market performance.

Analysis Q12: Comparative Analysis of Cash vs. Card Trips
In this section, I evaluated the operational and financial performance of trips depending on the payment method: Cash (which requires the use of the cash register) and Card (In-App and Business payments), starting with 31.03.2026 when I started cash trips. The purpose of this analysis is to understand if the payment method influences efficiency per minute or per kilometer and how this dynamic affects the operational flow, in view of supporting the target of 2000-2500 LEI/week in under 40 hours worked.
Key Figures Identified (From raw data Q09/Q12)
• CARD Trips (In-App / Business): Represent the majority of my activity, with a volume of 564 trips. The average value of a trip is 23.4 LEI, having an average paid distance of 6.0 km and an average empty pickup of 1.1 km.
• CASH Trips (Cash register): Accumulate a volume of 267 trips. The average value per trip is slightly lower, at 21.4 LEI, having an average paid distance of 5.6 km and an average empty pickup of 1.2 km.
• Identical operational efficiency: Both payment methods deliver almost perfectly equal profitability parameters: 1.4 LEI / minute on the time side and 3.6 - 3.7 LEI / km on the distance side.

Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• I treat both types of trips with equal operational priority: Figures clearly prove that there is no penalty or direct financial advantage regarding the rate per minute (1.4 LEI/minute) or per kilometer (3.6 vs 3.7 LEI/km) between Cash and Card. Therefore, accepting both flows ensures me the constant volume of orders necessary to reduce dead times and to gather the weekly threshold of 2000-2500 LEI in the allocated time.

What I DO NOT do to avoid unproductive times:
• Do not refuse Cash trips for convenience reasons: Since data shows that financial efficiency is the same, filtering or refusing Cash trips would artificially increase the unproductive waiting time in the application, making it impossible to fit below the threshold of 40 hours worked per week.
• Avoid operating errors at the cash register for Cash trips: Since Cash trips require additional interaction times at the end of the route for issuing the fiscal receipt, I make sure I run the process efficiently so as not to transform completion time into dead time that would artificially lower my real average of lei per minute at the wheel.

Analysis Q13: Financial Impact of Cancelled Trips
In this stage of the analysis, I extracted and evaluated all cases where trips were cancelled (either by the client or through non-appearance — no-show), but generated a direct net gain in the form of the cancellation fee. Although this indicator does not represent the main pillar for achieving my financial objective (2000-2500 LEI/week), dissecting this data gives me a clear understanding of how I can minimize time losses and operationally streamline every minute spent in the application.
Actionable Recommendations and Operational Strategy

What I do to maximize efficiency:
• I secure the cancellation fee: When I move towards the client and the pickup is cancelled late, the application automatically allocates these 12.75 LEI as compensation for time and fuel. In case I arrive at the address and the client does not appear, I always wait for the full timer of 5 minutes (2 + 3) until the status becomes eligible for no_show, securing this income for myself.
• Increased operational efficiency: From a financial and technical point of view, these amounts have an increased profitability rate, having an income per minute above the average income per minute of trips, because they generate revenues with zero kilometers traveled with the client, minimizing vehicle wear.

What I DO NOT do to avoid unproductive times:
• Do not cancel prematurely from the driver position: If the client is late at the pickup location, I avoid cancelling the trip out of impulse before the expiration of the regular time imposed by the platform. A premature cancellation on my part voids the right to the 12.75 LEI compensation, transforming the time and fuel consumed for travel into a pure operational loss.
