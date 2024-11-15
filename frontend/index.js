import { backend } from "declarations/backend";

let sortColumn = 'market_cap';
let sortDirection = 'desc';

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
    return data.sort(([, a], [, b]) => {
        let valueA, valueB;
        
        switch(column) {
            case 'name':
                valueA = a.name;
                valueB = b.name;
                break;
            case 'price':
                valueA = a.price;
                valueB = b.price;
                break;
            case 'market_cap':
                valueA = a.marketCap;
                valueB = b.marketCap;
                break;
            case 'fdv':
                valueA = a.fdv;
                valueB = b.fdv;
                break;
            case 'volume':
                valueA = a.volume24h;
                valueB = b.volume24h;
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
    
    sortedData.forEach(([symbol, token]) => {
        const row = document.createElement('tr');
        const chartId = `chart-${symbol}`;
        
        row.innerHTML = `
            <td>
                ${token.name} (${token.symbol})
            </td>
            <td>$${token.price.toFixed(2)}</td>
            <td>$${formatNumber(token.marketCap)}</td>
            <td>$${formatNumber(token.fdv)}</td>
            <td>$${formatNumber(token.volume24h)}</td>
            <td>$${formatNumber(token.dexVolume)}</td>
            <td>$${formatNumber(token.cexVolume)}</td>
            <td><div class="chart-container"><canvas id="${chartId}"></canvas></div></td>
        `;
        
        tbody.appendChild(row);
        createSparklineChart(chartId, token.priceHistory);
    });
}

async function updateData() {
    const loading = document.getElementById('loading');
    loading.style.display = 'block';
    
    try {
        const data = await backend.getAllTokenData();
        updateTable(data);
    } catch (error) {
        console.error('Error fetching data:', error);
    } finally {
        loading.style.display = 'none';
    }
}

async function initialize() {
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

initialize();
