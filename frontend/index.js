import { backend } from "declarations/backend";

const COINGECKO_API = 'https://api.coingecko.com/api/v3';
let sortColumn = 'market_cap';
let sortDirection = 'desc';

async function fetchCryptoData() {
    try {
        const response = await fetch(
            `${COINGECKO_API}/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=30&page=1&sparkline=true`
        );
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error fetching data:', error);
        return [];
    }
}

function formatNumber(num) {
    if (num >= 1e9) return (num / 1e9).toFixed(2) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(2) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(2) + 'K';
    return num.toFixed(2);
}

function createSparklineChart(containerId, data) {
    const ctx = document.getElementById(containerId).getContext('2d');
    return new Chart(ctx, {
        type: 'line',
        data: {
            labels: Array(data.length).fill(''),
            datasets: [{
                data: data,
                borderColor: data[0] < data[data.length - 1] ? '#28a745' : '#dc3545',
                borderWidth: 1,
                fill: false,
                pointRadius: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: { display: false },
                y: { display: false }
            },
            animation: false
        }
    });
}

function sortData(data, column, direction) {
    return data.sort((a, b) => {
        let valueA, valueB;
        
        switch(column) {
            case 'rank':
                valueA = a.market_cap_rank;
                valueB = b.market_cap_rank;
                break;
            case 'name':
                valueA = a.name;
                valueB = b.name;
                break;
            case 'price':
                valueA = a.current_price;
                valueB = b.current_price;
                break;
            case 'market_cap':
                valueA = a.market_cap;
                valueB = b.market_cap;
                break;
            case 'fdv':
                valueA = a.fully_diluted_valuation || 0;
                valueB = b.fully_diluted_valuation || 0;
                break;
            case 'volume':
                valueA = a.total_volume;
                valueB = b.total_volume;
                break;
            default:
                return 0;
        }
        
        if (direction === 'asc') {
            return valueA > valueB ? 1 : -1;
        } else {
            return valueA < valueB ? 1 : -1;
        }
    });
}

function updateTable(data) {
    const tbody = document.getElementById('cryptoTableBody');
    tbody.innerHTML = '';
    
    const sortedData = sortData(data, sortColumn, sortDirection);
    
    sortedData.forEach((coin, index) => {
        const row = document.createElement('tr');
        const chartId = `chart-${coin.id}`;
        
        row.innerHTML = `
            <td>${coin.market_cap_rank}</td>
            <td>
                <img src="${coin.image}" alt="${coin.name}" class="crypto-icon">
                ${coin.name} (${coin.symbol.toUpperCase()})
            </td>
            <td>$${coin.current_price.toFixed(2)}</td>
            <td>$${formatNumber(coin.market_cap)}</td>
            <td>$${formatNumber(coin.fully_diluted_valuation || 0)}</td>
            <td>$${formatNumber(coin.total_volume)}</td>
            <td><div class="chart-container"><canvas id="${chartId}"></canvas></div></td>
        `;
        
        tbody.appendChild(row);
        createSparklineChart(chartId, coin.sparkline_in_7d.price);
    });
}

async function initialize() {
    // Check if backend is healthy
    try {
        await backend.heartbeat();
    } catch (e) {
        console.error('Backend health check failed:', e);
    }
    
    document.querySelectorAll('th[data-sort]').forEach(th => {
        th.addEventListener('click', () => {
            const column = th.dataset.sort;
            if (sortColumn === column) {
                sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
            } else {
                sortColumn = column;
                sortDirection = 'desc';
            }
            updateData();
        });
    });
    
    await updateData();
    setInterval(updateData, 60000); // Update every minute
}

async function updateData() {
    const loading = document.getElementById('loading');
    loading.style.display = 'block';
    
    const data = await fetchCryptoData();
    updateTable(data);
    
    loading.style.display = 'none';
}

initialize();
