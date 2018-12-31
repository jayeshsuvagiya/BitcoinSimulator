// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {Socket} from "phoenix"
import Chart from "chart.js";

let socket = new Socket("/socket", {params: {token: window.userToken}});

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect();

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("btc_update:*", {});
channel.join()
    .receive("ok", resp => {
        console.log("Joined successfully", resp)
    })
    .receive("error", resp => {
        console.log("Unable to join", resp)
    });


let c_non = document.getElementById("no-of-nodes");
let c_notx = document.getElementById("no-of-transaction");
let c_aobtc = document.getElementById("no-of-bitcoins");
let c_aotx = document.getElementById("amt-of-transactions");
let trans_table = document.getElementById("trans-table");

channel.on("no_of_nodes", n => {
        console.log("non_recieved", n);
        c_non.innerText = n.non;
    }
);

channel.on("new_tran", ({html}) => {
        console.log("new_tran", html);
    //trans_table.appendText(html);
    $(trans_table).append(html);
    }
);

channel.on("no_of_tx", n => {
        console.log("no_of_tx", n);
        c_notx.innerText = n.notx;
    }
);

channel.on("amt_of_tx", n => {
        console.log("amt_of_tx", n);
        c_aotx.innerText = n.aotx;
    }
);

channel.on("amt_of_btc", n => {
        console.log("amt_of_btc", n);
        c_aobtc.innerText = n.aobtc;
    }
);

channel.on("amt_per_block", n => {
    console.log("chart_data",n);
    myChart.data.datasets[0].data.push(n.amt_blck);
    myChart.data.labels.push(n.y);
    myChart.update();
});


channel.on("tx_per_block", n => {
    console.log("chart_data",n);
    myChart2.data.datasets[0].data.push(n.tx_blck);
    myChart2.data.labels.push(n.x);
    myChart2.update();
});


let myChart;
let ctx = document.getElementById("tamount-chart");
const brandService = 'rgba(0,173,95,0.8)';
if (ctx) {
    ctx.height = 250;
     myChart = new Chart(ctx, {

        type: 'line',
        data: {
            //labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', ''],
            datasets: [
                {
                    label: 'Amount',
                    backgroundColor: brandService,
                    borderColor: 'transparent',
                    pointHoverBackgroundColor: '#fff',
                    borderWidth: 0,
                    data: []
                }
            ]
        },
        options: {
            maintainAspectRatio: true,
            legend: {
                display: false
            },
            responsive: true,
            scales: {
                xAxes: [{
                    gridLines: {
                        drawOnChartArea: true,
                        color: '#f2f2f2'
                    },
                    ticks: {
                        fontFamily: "Poppins",
                        fontSize: 12
                    }
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        fontFamily: "Poppins",
                        fontSize: 12
                    },
                    gridLines: {
                        display: true,
                        color: '#f2f2f2'

                    }
                }]
            }
        }
    });
}


let myChart2;
let ctx2 = document.getElementById("nt-chart");
if (ctx2) {
    ctx2.height = 250;
    myChart2 = new Chart(ctx2, {
        type: 'line',
        data: {
            //labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', ''],
            datasets: [
                {
                    label: 'Amount',
                    backgroundColor: brandService,
                    borderColor: 'transparent',
                    pointHoverBackgroundColor: '#fff',
                    borderWidth: 0,
                    data: []
                }
            ]
        },
        options: {
            maintainAspectRatio: true,
            legend: {
                display: false
            },
            responsive: true,
            scales: {
                xAxes: [{
                    gridLines: {
                        drawOnChartArea: true,
                        color: '#f2f2f2'
                    },
                    ticks: {
                        fontFamily: "Poppins",
                        fontSize: 12
                    }
                }],
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                        fontFamily: "Poppins",
                        fontSize: 12
                    },
                    gridLines: {
                        display: true,
                        color: '#f2f2f2'

                    }
                }]
            }
        }
    });
}


export default socket
