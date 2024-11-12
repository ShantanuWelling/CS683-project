#include <unordered_map>
#include <cstdint>
#include <bitset>
#include <unordered_set>
#include <iostream>
#include <set>

struct RegionAccessInfo {
    uint64_t trigger_offset;  // First cache line offset accessed
    uint64_t access_bitmap;   // 64-bit vector for cache line accesses
    bool has_trigger;         // To track if the trigger offset has been set
};


struct pair_hash {
    template <class T1, class T2>
    std::size_t operator()(const std::pair<T1, T2>& pair) const {
        std::size_t hash1 = std::hash<T1>{}(pair.first);
        std::size_t hash2 = std::hash<T2>{}(pair.second);
        return hash1 ^ (hash2 << 1); // or other combining technique
    }
};

class PatternData {
private:
    std::unordered_map<std::pair<uint64_t, uint64_t>, RegionAccessInfo, pair_hash> pattern_data;

public:
    void update_data(uint64_t ip, uint64_t addr) {
        // Calculate region and cache line offset
        uint64_t region = addr >> 12;  // Region of 4KB (12 bits)
        uint64_t offset = (addr >> 6) & 0x3F;  // Offset of 64 cache lines (6 bits)

        // Create the key (ip, region)
        std::pair<uint64_t, uint64_t> key = {ip, region};

        // Check if the key exists in the map
        auto& info = pattern_data[key];

        // Set the trigger offset if it hasn't been set yet
        if (!info.has_trigger) {
            info.trigger_offset = offset;
            info.has_trigger = true;
        }

        // Update the access bitmap for the cache line offset
        info.access_bitmap |= (1ULL << offset);
    }
    int get_size(){
        return pattern_data.size();
    }
    void get_pdr() {
        std::unordered_map<uint64_t, std::set<std::pair<uint64_t, uint64_t>>> duplications;
        for(auto& [key, value] : pattern_data){
            if(duplications.find(value.access_bitmap) == duplications.end()){
                duplications[value.access_bitmap] = std::set<std::pair<uint64_t, uint64_t> >();
            }
            duplications[value.access_bitmap].insert({key.first, value.trigger_offset});
        }
        int count = 0;
        for(auto& [key, value] : duplications){
            count += value.size();
        }
        std::cout << "PDR: " << static_cast<double>(count) / duplications.size() << std::endl;
        std::cout << "Total number of duplications: " << count << std::endl;
        std::cout << "Total number of unique patterns: " << duplications.size() << std::endl;
    }
    void get_pcr(){
        std::unordered_map<std::pair<uint64_t, uint64_t>,std::set<uint64_t>,pair_hash> collisions;
        for(auto& [key, value] : pattern_data){
            if(collisions.find({key.first, value.trigger_offset}) == collisions.end()){
                collisions[{key.first, value.trigger_offset}] = std::set<uint64_t>();
            }
            collisions[{key.first, value.trigger_offset}].insert(value.access_bitmap);
        }
        int count = 0;
        for(auto& [key, value] : collisions){
            count += value.size();
        }
        std::cout << "PCR: " << static_cast<double>(count) / collisions.size() << std::endl;
        std::cout << "Total number of collisions: " << count << std::endl;
        std::cout << "Total number of unique features: " << collisions.size() << std::endl;
    }
};