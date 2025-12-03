using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface ITimeService
    {
        DateTime GetIndianStandardTime();
        DateTime GetIndianStandardToday();
        Task<DateTime> GetOnlineIndianTimeAsync();
    }

    public class TimeService : ITimeService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private DateTime _lastSyncedTime;
        private DateTime _lastSyncSystemTime;
        private readonly TimeSpan _syncInterval = TimeSpan.FromMinutes(30); // Sync every 30 minutes
        private bool _isOnlineTimeAvailable = false;

        public TimeService(IHttpClientFactory httpClientFactory)
        {
            _httpClientFactory = httpClientFactory;
            // Initialize with system time
            _lastSyncedTime = DateTime.UtcNow;
            _lastSyncSystemTime = DateTime.UtcNow;
            
            // Try to sync on startup (fire and forget)
            _ = TrySyncTimeAsync();
        }

        /// <summary>
        /// Gets the current Indian Standard Time (IST)
        /// Uses cached online time if available, otherwise falls back to system time converted to IST
        /// </summary>
        public DateTime GetIndianStandardTime()
        {
            // If we have recently synced online time, use it
            if (_isOnlineTimeAvailable)
            {
                var elapsedSinceSync = DateTime.UtcNow - _lastSyncSystemTime;
                var currentTime = _lastSyncedTime.Add(elapsedSinceSync);
                
                // If sync is old, trigger a background sync
                if (elapsedSinceSync > _syncInterval)
                {
                    _ = TrySyncTimeAsync();
                }
                
                return currentTime;
            }

            // Fallback to system time converted to IST
            return ConvertUtcToIst(DateTime.UtcNow);
        }

        /// <summary>
        /// Attempts to fetch time from online source (WorldTimeAPI)
        /// Returns IST time if successful, otherwise returns system time in IST
        /// </summary>
        public async Task<DateTime> GetOnlineIndianTimeAsync()
        {
            try
            {
                var client = _httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(5);

                // Try WorldTimeAPI first
                var response = await client.GetStringAsync("http://worldtimeapi.org/api/timezone/Asia/Kolkata");
                var json = JsonDocument.Parse(response);
                var dateTimeString = json.RootElement.GetProperty("datetime").GetString();
                
                if (DateTime.TryParse(dateTimeString, out DateTime onlineTime))
                {
                    // Update cache
                    _lastSyncedTime = onlineTime;
                    _lastSyncSystemTime = DateTime.UtcNow;
                    _isOnlineTimeAvailable = true;
                    
                    Console.WriteLine($"[TimeService] Successfully synced with online time: {onlineTime:yyyy-MM-dd HH:mm:ss} IST");
                    return onlineTime;
                }
            }
            catch (HttpRequestException ex)
            {
                Console.WriteLine($"[TimeService] HTTP error fetching online time: {ex.Message}");
            }
            catch (TaskCanceledException)
            {
                Console.WriteLine("[TimeService] Timeout fetching online time");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TimeService] Error fetching online time: {ex.Message}");
            }

            // Try alternative API
            try
            {
                var client = _httpClientFactory.CreateClient();
                client.Timeout = TimeSpan.FromSeconds(5);

                var response = await client.GetStringAsync("https://timeapi.io/api/Time/current/zone?timeZone=Asia/Kolkata");
                var json = JsonDocument.Parse(response);
                var dateTimeString = json.RootElement.GetProperty("dateTime").GetString();
                
                if (DateTime.TryParse(dateTimeString, out DateTime onlineTime))
                {
                    // Update cache
                    _lastSyncedTime = onlineTime;
                    _lastSyncSystemTime = DateTime.UtcNow;
                    _isOnlineTimeAvailable = true;
                    
                    Console.WriteLine($"[TimeService] Successfully synced with alternative time API: {onlineTime:yyyy-MM-dd HH:mm:ss} IST");
                    return onlineTime;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TimeService] Alternative API also failed: {ex.Message}");
            }

            // All online sources failed, use system time
            _isOnlineTimeAvailable = false;
            var systemIst = ConvertUtcToIst(DateTime.UtcNow);
            Console.WriteLine($"[TimeService] Falling back to system time: {systemIst:yyyy-MM-dd HH:mm:ss} IST");
            return systemIst;
        }

        /// <summary>
        /// Background sync attempt (doesn't throw exceptions)
        /// </summary>
        private async Task TrySyncTimeAsync()
        {
            try
            {
                await GetOnlineIndianTimeAsync();
            }
            catch
            {
                // Silently fail for background sync
            }
        }

        /// <summary>
        /// Converts UTC time to IST (UTC +5:30)
        /// </summary>
        private DateTime ConvertUtcToIst(DateTime utcTime)
        {
            var istOffset = TimeSpan.FromHours(5.5); // IST is UTC+5:30
            return utcTime.Add(istOffset);
        }

        /// <summary>
        /// Gets the current time as "Today" for date comparisons (IST date without time)
        /// </summary>
        public DateTime GetIndianStandardToday()
        {
            var istNow = GetIndianStandardTime();
            return istNow.Date; // Returns date part only (midnight)
        }
    }
}
